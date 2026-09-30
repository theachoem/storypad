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

  group('title placeholder', () {
    testWidgets('shows in an empty leading heading, with a body after it', (tester) async {
      final controller = controllerFor('###\n\nWent to the beach.');
      await pumpStoryEditor(
        tester,
        controller,
        editor: RawEditor(controller: controller, titlePlaceholder: 'Title', placeholder: 'Write…'),
      );
      expect(find.text('Title', findRichText: true), findsOneWidget);
      expect(find.text('Write…', findRichText: true), findsNothing);

      placeCaret(controller, 0, 0);
      controller.editor.execute([
        InsertTextRequest(documentPosition: controller.selection.value!.extent, textToInsert: 'Trip', attributions: {}),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Title', findRichText: true), findsNothing);
      expect(controller.toMarkdown(), '### Trip\n\nWent to the beach.');
    });

    testWidgets('takes precedence over the placeholder when the page is just an empty heading', (tester) async {
      final controller = controllerFor('###');
      await pumpStoryEditor(
        tester,
        controller,
        editor: RawEditor(controller: controller, titlePlaceholder: 'Title', placeholder: 'Write…'),
      );
      expect(find.text('Title', findRichText: true), findsOneWidget);
      expect(find.text('Write…', findRichText: true), findsNothing);
    });

    testWidgets('does not show for an empty heading further down, or an empty paragraph first', (tester) async {
      final controller = controllerFor('Intro\n\n###');
      await pumpStoryEditor(
        tester,
        controller,
        editor: RawEditor(controller: controller, titlePlaceholder: 'Title'),
      );
      expect(find.text('Title', findRichText: true), findsNothing);

      final empty = controllerFor('');
      await pumpStoryEditor(
        tester,
        empty,
        editor: RawEditor(controller: empty, titlePlaceholder: 'Title'),
      );
      expect(find.text('Title', findRichText: true), findsNothing);
    });

    testWidgets('keeps the heading style, in the hint color', (tester) async {
      final controller = controllerFor('###\n\nbody');
      await pumpStoryEditor(
        tester,
        controller,
        editor: RawEditor(
          controller: controller,
          titlePlaceholder: 'Title',
          placeholderStyle: const TextStyle(color: Color(0xFF00FF00)),
        ),
      );
      // The style a text run is drawn with: its span's style merged over its ancestors'.
      TextStyle styleOf(String text) {
        final root = tester.widget<RichText>(find.text(text, findRichText: true)).text;
        TextStyle? found;
        void visit(InlineSpan span, TextStyle inherited) {
          final style = inherited.merge(span.style);
          if (span is TextSpan && span.text == text) found = style;
          if (span is TextSpan) span.children?.forEach((child) => visit(child, style));
        }

        visit(root, const TextStyle());
        return found!;
      }

      final hintStyle = styleOf('Title');
      final bodyStyle = styleOf('body');
      expect(hintStyle.color, const Color(0xFF00FF00));
      expect(hintStyle.fontSize, greaterThan(bodyStyle.fontSize!));
    });
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
