import 'package:flutter/painting.dart' show Color, TextAlign;
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('headings 1–6 and back to a paragraph', () {
    final controller = controllerFor('Title');
    placeCaret(controller, 0, 0);

    for (var level = 1; level <= 6; level++) {
      controller.actions.setHeading(level);
      expect(controller.actions.headingLevel, level);
    }
    expect(controller.toMarkdown(), '###### Title');

    controller.actions.setHeading(null);
    expect(controller.actions.headingLevel, isNull);
    expect(controller.toMarkdown(), 'Title');
  });

  test('quote and code block toggles, across several blocks', () {
    final controller = controllerFor('a\n\nb');
    selectText(controller, 0, 0, 1, 1);

    controller.actions.toggleBlockquote();
    expect(controller.actions.isBlockquote, isTrue);
    expect(controller.toMarkdown(), '> a\n\n> b');

    controller.actions.toggleBlockquote();
    expect(controller.toMarkdown(), 'a\n\nb');

    controller.actions.toggleCodeBlock();
    expect(controller.actions.isCodeBlock, isTrue);
  });

  test('list and task toggles keep indent', () {
    final controller = controllerFor('    - nested');
    placeCaret(controller, 0, 0);

    controller.actions.toggleTaskList();
    expect(controller.toMarkdown(), '    - [ ] nested');

    controller.actions.toggleOrderedList();
    expect(controller.toMarkdown(), '    1. nested');

    controller.actions.toggleOrderedList();
    expect(controller.toMarkdown(), '<div data-indent="1">\n\nnested\n\n</div>');

    controller.actions.toggleBulletList();
    expect(controller.actions.isBulletList, isTrue);
    expect(controller.toMarkdown(), '    - nested');
  });

  test('alignment applies to paragraphs, headings, quotes, list items and tasks; code is skipped', () {
    final controller = controllerFor('# h\n\np\n\n- item\n- [ ] task\n\n```\ncode\n```');
    selectText(controller, 0, 0, 4, 4);

    controller.actions.setAlignment(TextAlign.center);

    expect(
      controller.toMarkdown(),
      '<div style="text-align:center">\n\n# h\n\n</div>\n\n<div style="text-align:center">\n\np\n\n</div>\n\n'
      '<div style="text-align:center">\n\n- item\n- [ ] task\n\n</div>\n\n```\ncode\n```',
    );
    placeCaret(controller, 3, 0);
    expect(controller.actions.alignment, TextAlign.center);

    controller.actions.undo();
    expect(controller.toMarkdown(), '# h\n\np\n\n- item\n- [ ] task\n\n```\ncode\n```');
  });

  test('list, task and heading toggles keep alignment', () {
    final controller = controllerFor('<div style="text-align:center">\n\np\n\n</div>');
    placeCaret(controller, 0, 0);
    const centered = '<div style="text-align:center">\n\n%s\n\n</div>';

    controller.actions.toggleBulletList();
    expect(controller.toMarkdown(), centered.replaceFirst('%s', '- p'));

    controller.actions.toggleTaskList();
    expect(controller.toMarkdown(), centered.replaceFirst('%s', '- [ ] p'));

    controller.actions.setHeading(2);
    expect(controller.toMarkdown(), centered.replaceFirst('%s', '## p'));

    controller.actions.toggleOrderedList();
    controller.actions.toggleOrderedList();
    expect(controller.toMarkdown(), centered.replaceFirst('%s', 'p'));
    expect(controller.actions.alignment, TextAlign.center);
  });

  test('horizontal rule at the caret', () {
    final controller = controllerFor('Hello');
    placeCaret(controller, 0, 5);

    controller.actions.insertHorizontalRule();
    expect(controller.toMarkdown(), 'Hello\n\n---');
  });

  test('undo and redo', () {
    final controller = controllerFor('Hello');
    expect(controller.actions.canUndo, isFalse);

    selectNode(controller, 0);
    controller.actions.toggleBold();
    expect(controller.actions.canUndo, isTrue);

    controller.actions.undo();
    expect(controller.toMarkdown(), 'Hello');
    expect(controller.actions.canRedo, isTrue);

    controller.actions.redo();
    expect(controller.toMarkdown(), '**Hello**');
  });

  group('undo counts edits, not caret moves', () {
    test('nothing to undo after only moving the caret', () {
      final controller = controllerFor('Hello\n\nWorld');
      controller.actions.placeCaretAtEnd();
      controller.actions.moveCaret(forward: false);
      expect(controller.editor.history, isNotEmpty, reason: 'caret moves are history steps');
      expect(controller.actions.canUndo, isFalse);

      controller.actions.undo();
      expect(controller.composer.selection, isNotNull, reason: 'undo did not drop the caret');
    });

    test('one undo undoes the last edit, with the caret moves after it', () {
      final controller = controllerFor('Hello');
      selectNode(controller, 0);
      controller.actions.toggleBold();
      controller.actions.placeCaretAtEnd();
      controller.actions.moveCaret(forward: false);

      controller.actions.undo();
      expect(controller.toMarkdown(), 'Hello');
      expect(controller.actions.canUndo, isFalse);

      controller.actions.redo();
      expect(controller.toMarkdown(), '**Hello**');
      expect(controller.actions.canRedo, isFalse);
    });

    test('an action that changes nothing adds no undo step', () {
      final controller = controllerFor('<div style="text-align:center">\n\nHELLO\n\n</div>');
      controller.actions.placeCaretAtEnd();
      final steps = controller.editor.history.length;

      controller.actions.setAlignment(TextAlign.center);
      selectNode(controller, 0);
      controller.actions.transformSelectedText((text) => text.toUpperCase());
      expect(controller.editor.history.length, steps);
    });

    test('undoing a newline after a no-op alignment keeps the text before it', () {
      final controller = controllerFor('<div style="text-align:center">\n\nHello\n\n</div>');
      controller.actions.placeCaretAtEnd();
      controller.actions.setAlignment(TextAlign.center);
      controller.editor.execute([InsertNewlineAtCaretRequest(Editor.createNodeId())]);
      expect(controller.document.nodeCount, 2);

      controller.actions.undo();
      expect(controller.document.nodeCount, 1);
      expect(controller.toMarkdown(), '<div style="text-align:center">\n\nHello\n\n</div>');

      controller.actions.redo();
      expect(controller.document.nodeCount, 2);
    });
  });

  test('a code block holds plain text only: converting strips formatting, and formatting/indent do not apply', () {
    final controller = controllerFor('<div data-indent="1">\n\n**Hello** code\n\n</div>');
    placeCaret(controller, 0, 0);

    controller.actions.toggleCodeBlock();
    expect(controller.toMarkdown(), '```\nHello code\n```');
    expect((nodeAt(controller, 0) as dynamic).text.getAllAttributionsAt(0), isEmpty);

    selectNode(controller, 0);
    controller.actions.toggleBold();
    controller.actions.setTextColor(const Color(0xFFFF0000));
    expect(controller.actions.canIndent, isFalse);
    controller.actions.indent();
    expect(controller.actions.canUndo, isTrue);
    expect((nodeAt(controller, 0) as dynamic).text.getAllAttributionsAt(0), isEmpty, reason: 'shown == saved');
  });
}
