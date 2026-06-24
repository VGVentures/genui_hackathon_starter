import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_template/catalog.dart';
import 'package:genui_template/conversation.dart';
import 'package:genui_template/home_page.dart';
import 'package:genui_template/model/model_client.dart';

// A fake ModelClient whose generateResponse returns empty, throws, or hangs.
class _FakeModelClient extends ModelClient {
  _FakeModelClient({this._shouldThrow = false, this._shouldHang = false});

  final bool _shouldThrow;
  final bool _shouldHang;

  @override
  Stream<String> generateResponse() async* {
    if (_shouldThrow) throw Exception('test error');
    if (_shouldHang) await Future<void>.delayed(const Duration(days: 1));
  }

  @override
  void dispose() => latestResponse.dispose();
}

GenUiSession _makeSession({bool shouldThrow = false}) => GenUiSession(
  catalog: buildCatalog(),
  modelClient: _FakeModelClient(shouldThrow: shouldThrow),
);

void main() {
  group('HomePage', () {
    testWidgets('shows SnackBar when the model throws a ConversationError', (
      tester,
    ) async {
      final session = _makeSession(shouldThrow: true);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(home: HomePage.withSession(session)),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Request failed:'),
        findsOneWidget,
      );
    });

    testWidgets('renders the app bar and message input on load', (
      tester,
    ) async {
      final session = _makeSession();
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(home: HomePage.withSession(session)),
      );

      expect(find.text('GenUI'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows progress indicator while the model is processing', (
      tester,
    ) async {
      final session = GenUiSession(
        catalog: buildCatalog(),
        modelClient: _FakeModelClient(shouldHang: true),
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(home: HomePage.withSession(session)),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.text('Send'));
      // Single pump: the message is in-flight, processing state is active.
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
