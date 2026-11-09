import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';

// Runs both styles: `flutter test` (Material) and `--dart-define=CUPERTINO=yes` (iOS).
void main() {
  const footerKey = Key('footer');
  final input = find.byWidgetPredicate((widget) => widget is TextField || widget is CupertinoTextField);

  Future<void> pump(
    WidgetTester tester, {
    String? Function(String?)? validator,
    String? initialText,
    Widget? footer,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: SpTextInputsPage(
          fields: [SpTextInputField(initialText: initialText, hintText: 'Title', validator: validator)],
          footer: footer,
        ),
      ),
    );
  }

  group('SpTextInputsPage', () {
    testWidgets('shows the footer below the fields', (tester) async {
      await pump(tester, footer: const SizedBox(key: footerKey, height: 40.0));

      expect(tester.getRect(find.byKey(footerKey)).top, greaterThan(tester.getRect(input).bottom));
    });

    // In a sheet: as tall as the form, not the screen.
    testWidgets('contentOnly sizes to its content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: Column(
              mainAxisSize: .min,
              children: [
                Flexible(
                  child: SpTextInputsPage(contentOnly: true, fields: [SpTextInputField(hintText: 'Title')]),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsNothing);
      expect(tester.getSize(find.byType(SpTextInputsPage)).height, lessThan(300.0));
    });

    testWidgets('shows an error for an empty field', (tester) async {
      await pump(tester, validator: (value) => (value ?? '').isEmpty ? 'Required' : null);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('validates the prefilled text, not only typed text', (tester) async {
      await pump(tester, initialText: 'Travel', validator: (value) => (value ?? '').isEmpty ? 'Required' : null);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Required'), findsNothing);
    });
  });
}
