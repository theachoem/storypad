import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';

// Runs both styles: `flutter test` (Material) and `--dart-define=CUPERTINO=yes` (iOS).
void main() {
  const trailingKey = Key('trailing');
  final input = find.byWidgetPredicate((widget) => widget is TextField || widget is CupertinoTextField);

  Future<void> pump(WidgetTester tester, {String? Function(String?)? validator, String? initialText}) {
    return tester.pumpWidget(
      MaterialApp(
        // The app's field border (see AppTheme).
        theme: ThemeData(
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
        home: SpTextInputsPage(
          fields: [
            SpTextInputField(
              initialText: initialText,
              hintText: 'Title',
              validator: validator,
              trailing: const ColoredBox(key: trailingKey, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  group('SpTextInputsPage trailing', () {
    testWidgets('is a square as tall as the field, up to the max size, centered on it', (tester) async {
      await pump(tester);

      final field = tester.getRect(input);
      final trailing = tester.getRect(find.byKey(trailingKey));
      expect(trailing.height, min(field.height, SpTextInputsPage.trailingMaxSize));
      expect(trailing.width, trailing.height);
      expect(trailing.center.dy, field.center.dy);

      // Material's field is compact beside it (iOS fields already are).
      if (!kIsCupertino) expect(field.height, SpTextInputsPage.trailingMaxSize);
    });

    testWidgets('keeps its size when the field shows an error', (tester) async {
      await pump(tester, validator: (value) => (value ?? '').isEmpty ? 'Required' : null);
      final before = tester.getSize(find.byKey(trailingKey));

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
      expect(tester.getSize(find.byKey(trailingKey)), before);
    });

    testWidgets('validates the prefilled text, not only typed text', (tester) async {
      await pump(tester, initialText: 'Travel', validator: (value) => (value ?? '').isEmpty ? 'Required' : null);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Required'), findsNothing);
    });
  });
}
