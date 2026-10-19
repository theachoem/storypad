import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Indent works as in most editors, the same with a hardware keyboard and an on-screen one: Enter keeps it, Enter on an
/// empty nested item and Backspace at a line's start move out one level, and Markdown shortcuts keep it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void enter(StoryEditorController controller, int index, [int? offset]) {
    placeCaret(controller, index, offset ?? (nodeAt(controller, index) as TextNode).text.length);
    controller.editor.execute([InsertNewlineAtCaretRequest()]);
  }

  /// An on-screen keyboard's Backspace at the start of a line (a hardware key runs super_editor's keyboard actions).
  void backspaceAtStart(StoryEditorController controller, int index) {
    placeCaret(controller, index, 0);
    controller.editor.execute([DeleteUpstreamAtBeginningOfNodeRequest(nodeAt(controller, index))]);
  }

  int indentOf(DocumentNode node) => switch (node) {
    ListItemNode() => node.indent,
    TaskNode() => node.indent,
    ParagraphNode() => node.indent,
    _ => throw StateError('no indent: $node'),
  };

  group('Enter keeps the indent', () {
    for (final (name, markdown) in [
      ('a bullet', '- a\n    - b'),
      ('a numbered item', '1. a\n    1. b'),
      ('a task', '- [ ] a\n    - [ ] b'),
      ('a paragraph', '<div data-indent="1">\n\nb\n\n</div>'),
    ]) {
      final last = markdown.startsWith('<') ? 0 : 1;
      for (final (where, offset) in [('at the end', null), ('in the middle', 1), ('at the start', 0)]) {
        test('$name, $where', () {
          final controller = controllerFor(markdown.replaceFirst('b', 'bc'));
          enter(controller, last, offset);

          expect(controller.document.nodeCount, last + 2);
          expect(indentOf(nodeAt(controller, last)), 1);
          expect(indentOf(nodeAt(controller, last + 1)), 1);
          expect(controller.selection.value!.extent.nodeId, nodeAt(controller, last + 1).id);
        });
      }
    }

    test('a new task is unchecked, at its indent', () {
      final controller = controllerFor('- [x] a\n    - [x] b');
      enter(controller, 1);
      expect(controller.toMarkdown(), '- [x] a\n    - [x] b\n    - [ ]');
    });

    test('an empty indented paragraph stays indented', () {
      final controller = controllerFor('<div data-indent="2">\n\n&nbsp;\n\n</div>');
      enter(controller, 0);
      expect([indentOf(nodeAt(controller, 0)), indentOf(nodeAt(controller, 1))], [2, 2]);
    });

    for (final markdown in ['### Title', '> quoted']) {
      test('the line Enter adds above an indented "$markdown" is indented too', () {
        final controller = controllerFor('<div data-indent="1">\n\n$markdown\n\n</div>');
        enter(controller, 0, 0);
        expect(indentOf(nodeAt(controller, 0)), 1);
        expect((nodeAt(controller, 0) as TextNode).text.toPlainText(), isEmpty);
        expect(indentOf(nodeAt(controller, 1)), 1);
      });
    }

    test('after a heading or quote, the next line keeps its indent', () {
      final controller = controllerFor('<div data-indent="1">\n\n### Title\n\n</div>');
      enter(controller, 0);
      expect(indentOf(nodeAt(controller, 1)), 1);
    });

    test('one undo takes back a task\'s new line', () {
      final controller = controllerFor('- [ ] a\n    - [ ] b');
      enter(controller, 1);
      controller.editor.undo();
      expect(controller.toMarkdown(), '- [ ] a\n    - [ ] b');
    });
  });

  group('Enter on an empty nested item moves it out one level', () {
    for (final (name, nested, outer, paragraph) in [
      ('a bullet', '- a\n        - ', '- a\n    -', '- a\n\n&nbsp;'),
      ('a numbered item', '1. a\n        1. ', '1. a\n    1.', '1. a\n\n&nbsp;'),
      ('a task', '- [ ] a\n        - [ ] ', '- [ ] a\n    - [ ]', '- [ ] a\n\n&nbsp;'),
    ]) {
      test('$name, then out of the list at the outermost level', () {
        final controller = controllerFor(nested);
        enter(controller, 1);
        expect(indentOf(nodeAt(controller, 1)), 1);
        expect(controller.toMarkdown(), outer);

        enter(controller, 1);
        expect(indentOf(nodeAt(controller, 1)), 0);
        enter(controller, 1);
        expect(controller.toMarkdown(), paragraph);
        expect(controller.document.nodeCount, 2, reason: 'moving out adds no line');
      });
    }
  });

  group('Backspace at the start of an indented line moves it out one level (on-screen keyboard)', () {
    for (final (name, markdown, outdented) in [
      ('a bullet', '- a\n        - b', '- a\n    - b'),
      ('a numbered item', '1. a\n        1. b', '1. a\n    1. b'),
      ('a task', '- [ ] a\n        - [ ] b', '- [ ] a\n    - [ ] b'),
      ('a paragraph', 'a\n\n<div data-indent="2">\n\nb\n\n</div>', 'a\n\n<div data-indent="1">\n\nb\n\n</div>'),
      ('a quote', 'a\n\n<div data-indent="1">\n\n> b\n\n</div>', 'a\n\n> b'),
    ]) {
      test(name, () {
        final controller = controllerFor(markdown);
        backspaceAtStart(controller, 1);
        expect(controller.toMarkdown(), outdented);
      });
    }

    test('at the outermost level, a list item becomes a paragraph as before', () {
      final controller = controllerFor('- a\n- b');
      backspaceAtStart(controller, 1);
      expect(controller.toMarkdown(), '- a\n\nb');
    });
  });

  group('Markdown shortcuts keep the line\'s indent', () {
    for (final (typed, expected) in [
      ('- ', '        -'),
      ('1. ', '        1.'),
      ('> ', '<div data-indent="2">\n\n>\n\n</div>'),
      ('# ', '<div data-indent="2">\n\n#\n\n</div>'),
    ]) {
      test('"$typed"', () {
        final controller = controllerFor('<div data-indent="2">\n\n&nbsp;\n\n</div>');
        placeCaret(controller, 0, 0);
        for (final character in typed.split('')) {
          controller.editor.execute([
            InsertTextRequest(
              documentPosition: controller.selection.value!.extent,
              textToInsert: character,
              attributions: {},
            ),
          ]);
        }
        expect(indentOf(nodeAt(controller, 0)), 2);
        expect(controller.toMarkdown(), expected);
      });
    }

    test('a typed number continuing a list keeps that list\'s level on an unindented line', () {
      final controller = controllerFor('1. a\n    1. b\n\n&nbsp;');
      placeCaret(controller, 2, 0);
      for (final character in '2. '.split('')) {
        controller.editor.execute([
          InsertTextRequest(
            documentPosition: controller.selection.value!.extent,
            textToInsert: character,
            attributions: {},
          ),
        ]);
      }
      expect(controller.toMarkdown(), '1. a\n    1. b\n    1.');
    });
  });

  group('hardware keys', () {
    Future<StoryEditorController> pumpWithCaret(WidgetTester tester, String markdown, int index, int offset) async {
      final controller = StoryEditorController(embeds: const [], markdown: markdown);
      addTearDown(controller.dispose);
      await StoryEditorTester.pump(tester, controller);
      controller.focusNode.requestFocus();
      await tester.pump();
      placeCaret(controller, index, offset);
      await tester.pump();
      return controller;
    }

    testWidgets('Enter on an empty indented paragraph keeps its indent, as an on-screen keyboard does', (tester) async {
      final controller = await pumpWithCaret(tester, '<div data-indent="2">\n\n&nbsp;\n\n</div>', 0, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(controller.document.nodeCount, 2);
      expect([indentOf(nodeAt(controller, 0)), indentOf(nodeAt(controller, 1))], [2, 2]);
    }, variant: const TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.linux}));

    testWidgets('Enter in an indented task keeps its indent', (tester) async {
      final controller = await pumpWithCaret(tester, '- [ ] a\n    - [ ] b', 1, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(controller.toMarkdown(), '- [ ] a\n    - [ ] b\n    - [ ]');
    }, variant: const TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.linux}));

    testWidgets('Backspace at the start of an indented item moves it out one level', (tester) async {
      final controller = await pumpWithCaret(tester, '- a\n        - b', 1, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(controller.toMarkdown(), '- a\n    - b');
    }, variant: const TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.linux}));
  });
}
