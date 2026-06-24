import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' hide ChatMessage;
import 'package:genui_template/model/model_client.dart';
import 'package:genui_template/prompt.dart';
import 'package:openai_dart/openai_dart.dart' hide MessageRole;

/// A [ModelClient] backed by a model hosted on Featherless.ai.
///
/// Featherless exposes an OpenAI-compatible API, so this client drives it with
/// [package:openai_dart] pointed at the Featherless base URL. Owns the client,
/// the running conversation history, and the A2UI system prompt derived from
/// the widget [Catalog]. Streams the raw text chunks of each model turn.
class FeatherlessModelClient extends ModelClient {
  FeatherlessModelClient({
    required Catalog catalog,
    String? apiKey,
    String? model,
  }) : _model = model ?? _defaultModel,
       _client = OpenAIClient.withApiKey(
         apiKey ?? _defaultApiKey,
         baseUrl: _baseUrl,
       ),
       _systemPrompt = PromptBuilder.chat(
         catalog: catalog,
         systemPromptFragments: [systemPrompt],
       ).systemPromptJoined();

  /// Test-only constructor that accepts a pre-built [OpenAIClient].
  @visibleForTesting
  FeatherlessModelClient.withClient({
    required Catalog catalog,
    required this._client,
    String? model,
  }) : _model = model ?? _defaultModel,
       _systemPrompt = PromptBuilder.chat(
         catalog: catalog,
         systemPromptFragments: [systemPrompt],
       ).systemPromptJoined();

  static const String _baseUrl = 'https://api.featherless.ai/v1';

  // HuggingFace-style org/model slug. Strong instruction-following for A2UI's
  // structured output. Override via constructor or --dart-define.
  static const String _defaultModel = 'Qwen/Qwen2.5-72B-Instruct';

  // API key supplied at build time via
  // `flutter run --dart-define=FEATHERLESS_API_KEY=...`.
  static const String _defaultApiKey = String.fromEnvironment(
    'FEATHERLESS_API_KEY',
  );

  final String _model;
  final OpenAIClient _client;
  final String _systemPrompt;

  @override
  Stream<String> generateResponse() async* {
    final stream = _client.chat.completions.createStream(
      ChatCompletionCreateRequest(
        model: _model,
        messages: [
          ChatMessage.system(_systemPrompt),
          ...history.map(_toMessage),
        ],
      ),
    );

    await for (final event in stream) {
      final delta = event.textDelta;
      if (delta == null || delta.isEmpty) continue;
      yield delta;
    }
  }

  // Maps a model-agnostic history entry to an OpenAI-compatible ChatMessage.
  ChatMessage _toMessage(ModelMessage message) => switch (message.role) {
    MessageRole.user => ChatMessage.user(message.text),
    MessageRole.model => ChatMessage.assistant(content: message.text),
  };

  @override
  void dispose() {
    latestResponse.dispose();
    _client.close();
  }
}
