import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart' hide ChatMessage;
import 'package:genui_template/model/featherless_model_client.dart';
import 'package:genui_template/model/model_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openai_dart/openai_dart.dart' hide MessageRole;

class _MockOpenAIClient extends Mock implements OpenAIClient {}

class _MockChatResource extends Mock implements ChatResource {}

class _MockChatCompletionsResource extends Mock
    implements ChatCompletionsResource {}

// Minimal stream event helpers.
ChatStreamEvent _chunk(String content) => ChatStreamEvent(
  choices: [ChatStreamChoice(delta: ChatDelta(content: content))],
);

const _nullChunk = ChatStreamEvent(
  choices: [ChatStreamChoice(delta: ChatDelta())],
);

FeatherlessModelClient _makeClient({
  required _MockChatCompletionsResource completions,
  String? model,
}) {
  final client = _MockOpenAIClient();
  final chat = _MockChatResource();
  when(() => client.chat).thenReturn(chat);
  when(() => chat.completions).thenReturn(completions);
  when(client.close).thenReturn(null);
  return FeatherlessModelClient.withClient(
    catalog: const Catalog(<CatalogItem>[]),
    client: client,
    model: model,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ChatCompletionCreateRequest(model: 'test', messages: []),
    );
  });

  group('FeatherlessModelClient', () {
    group('model selection', () {
      test('uses Qwen/Qwen2.5-72B-Instruct by default', () async {
        final completions = _MockChatCompletionsResource();
        when(
          () => completions.createStream(any()),
        ).thenAnswer((_) => const Stream.empty());
        final sut = _makeClient(completions: completions);
        await sut.sendMessage('hi').drain<void>();
        final captured = verify(
          () => completions.createStream(captureAny()),
        ).captured;
        final req = captured.single as ChatCompletionCreateRequest;
        expect(req.model, equals('Qwen/Qwen2.5-72B-Instruct'));
      });

      test('uses override model when provided', () async {
        final completions = _MockChatCompletionsResource();
        when(
          () => completions.createStream(any()),
        ).thenAnswer((_) => const Stream.empty());
        final sut = _makeClient(completions: completions, model: 'my/model');
        await sut.sendMessage('hi').drain<void>();
        final captured = verify(
          () => completions.createStream(captureAny()),
        ).captured;
        final req = captured.single as ChatCompletionCreateRequest;
        expect(req.model, equals('my/model'));
      });
    });

    group('message construction', () {
      test('prepends system message on every turn', () async {
        final completions = _MockChatCompletionsResource();
        when(
          () => completions.createStream(any()),
        ).thenAnswer((_) => const Stream.empty());
        final sut = _makeClient(completions: completions);
        await sut.sendMessage('hi').drain<void>();
        final req =
            verify(() => completions.createStream(captureAny())).captured.single
                as ChatCompletionCreateRequest;
        expect(req.messages.first, isA<SystemMessage>());
      });

      test('maps user history entry to UserMessage', () async {
        final completions = _MockChatCompletionsResource();
        when(
          () => completions.createStream(any()),
        ).thenAnswer((_) => const Stream.empty());
        final sut = _makeClient(completions: completions);
        sut.history.add(const ModelMessage.user('hello'));
        await sut.sendMessage('next').drain<void>();
        final req =
            verify(() => completions.createStream(captureAny())).captured.single
                as ChatCompletionCreateRequest;
        final userMsgs = req.messages.whereType<UserMessage>().toList();
        expect(userMsgs.any((m) => m.text == 'hello'), isTrue);
      });

      test('maps model history entry to AssistantMessage', () async {
        final completions = _MockChatCompletionsResource();
        when(
          () => completions.createStream(any()),
        ).thenAnswer((_) => const Stream.empty());
        final sut = _makeClient(completions: completions);
        sut.history.add(const ModelMessage.model('reply'));
        await sut.sendMessage('next').drain<void>();
        final req =
            verify(() => completions.createStream(captureAny())).captured.single
                as ChatCompletionCreateRequest;
        final assistantMsgs = req.messages
            .whereType<AssistantMessage>()
            .toList();
        expect(assistantMsgs.any((m) => m.content == 'reply'), isTrue);
      });
    });

    group('chunk filtering', () {
      test('yields non-empty chunks in order', () {
        final completions = _MockChatCompletionsResource();
        when(() => completions.createStream(any())).thenAnswer(
          (_) => Stream.fromIterable([_chunk('a'), _chunk('b'), _chunk('c')]),
        );
        final sut = _makeClient(completions: completions);
        expect(
          sut.sendMessage('hi'),
          emitsInOrder(<Object>['a', 'b', 'c', emitsDone]),
        );
      });

      test('skips null content deltas', () {
        final completions = _MockChatCompletionsResource();
        when(() => completions.createStream(any())).thenAnswer(
          (_) => Stream.fromIterable([_nullChunk, _chunk('ok')]),
        );
        final sut = _makeClient(completions: completions);
        expect(
          sut.sendMessage('hi'),
          emitsInOrder(<Object>['ok', emitsDone]),
        );
      });

      test('skips empty content deltas', () {
        final completions = _MockChatCompletionsResource();
        when(() => completions.createStream(any())).thenAnswer(
          (_) => Stream.fromIterable([_chunk(''), _chunk('hi')]),
        );
        final sut = _makeClient(completions: completions);
        expect(
          sut.sendMessage('hi'),
          emitsInOrder(<Object>['hi', emitsDone]),
        );
      });

      test('propagates stream errors from the API', () {
        final completions = _MockChatCompletionsResource();
        when(() => completions.createStream(any())).thenAnswer(
          (_) => Stream.error(Exception('API error')),
        );
        final sut = _makeClient(completions: completions);
        expect(
          sut.sendMessage('hi'),
          emitsError(isA<Exception>()),
        );
      });
    });

    group('dispose', () {
      test('closes the OpenAIClient', () {
        final completions = _MockChatCompletionsResource();
        final chat = _MockChatResource();
        final client = _MockOpenAIClient();
        when(() => client.chat).thenReturn(chat);
        when(() => chat.completions).thenReturn(completions);
        when(client.close).thenReturn(null);
        FeatherlessModelClient.withClient(
          catalog: const Catalog(<CatalogItem>[]),
          client: client,
        ).dispose();
        verify(client.close).called(1);
      });

      test('disposes latestResponse notifier', () {
        final completions = _MockChatCompletionsResource();
        final sut = _makeClient(completions: completions)..dispose();
        expect(() => sut.latestResponse.value, throwsFlutterError);
      });
    });
  });
}
