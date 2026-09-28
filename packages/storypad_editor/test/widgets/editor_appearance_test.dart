import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Placeholder, checkbox and color hooks on RawEditor.
void main() {
  testWidgets('the placeholder shows while the document is empty', (tester) async {
    final controller = controllerFor('');
    await pumpStoryEditor(
      tester,
      controller,
      editor: RawEditor(controller: controller, placeholder: 'Write…'),
    );
    expect(find.text('Write…', findRichText: true), findsOneWidget);

    placeCaret(controller, 0, 0);
    controller.editor.execute([
      InsertTextRequest(documentPosition: controller.selection.value!.extent, textToInsert: 'Hi', attributions: {}),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Write…', findRichText: true), findsNothing);
  });

  for (final readOnly in [false, true]) {
    testWidgets('checkboxes can be turned off${readOnly ? ' (read-only)' : ''}', (tester) async {
      final controller = controllerFor('- [ ] task', readOnly: readOnly);
      await pumpStoryEditor(tester, controller, editor: RawEditor(controller: controller, checkboxesEnabled: false));

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.toMarkdown(), '- [ ] task');
    });
  }

  testWidgets('checkboxes toggle by default, also while read-only', (tester) async {
    final controller = controllerFor('- [ ] task', readOnly: true);
    await pumpStoryEditor(tester, controller);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(controller.toMarkdown(), '- [x] task');
  });

  testWidgets('selection color: given, else the theme\'s', (tester) async {
    final controller = controllerFor('Hello');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(textSelectionTheme: const TextSelectionThemeData(selectionColor: Color(0x5500FF00))),
        home: Scaffold(body: RawEditor(controller: controller)),
      ),
    );
    expect(
      tester.widget<SuperEditor>(find.byType(SuperEditor)).selectionStyles.selectionColor,
      const Color(0x5500FF00),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RawEditor(controller: controller, selectionColor: const Color(0x55FF0000)),
        ),
      ),
    );
    expect(
      tester.widget<SuperEditor>(find.byType(SuperEditor)).selectionStyles.selectionColor,
      const Color(0x55FF0000),
    );
  });

  testWidgets('caret color: given, else the theme\'s cursor color', (tester) async {
    final controller = controllerFor('Hello');
    Color caretColor() => tester
        .widget<SuperEditor>(find.byType(SuperEditor))
        .documentOverlayBuilders
        .whereType<DefaultCaretOverlayBuilder>()
        .single
        .caretStyle
        .color;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xFF00FF00))),
        home: Scaffold(body: RawEditor(controller: controller)),
      ),
    );
    expect(caretColor(), const Color(0xFF00FF00));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RawEditor(controller: controller, caretColor: const Color(0xFFFF0000)),
        ),
      ),
    );
    expect(caretColor(), const Color(0xFFFF0000));
  });
}
