import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

/// The editor never adds a line of its own: what's on the page is what's written -- blank lines included, wherever
/// they are. After a trailing embed the caret sits right after it, and typing or Enter starts a new line there.
void main() {
  const endsWithEmbed = 'Hello\n\n<sp-sticker name="cat"></sp-sticker>';

  StoryEditorController controllerFor(String markdown, {bool readOnly = false}) {
    final controller = StoryEditorController(embeds: testEmbeds, markdown: markdown, readOnly: readOnly);
    addTearDown(controller.dispose);
    return controller;
  }

  void caretAfterLast(StoryEditorController controller) {
    controller.composer.setSelectionWithReason(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: controller.document.last.id,
          nodePosition: const UpstreamDownstreamNodePosition.downstream(),
        ),
      ),
    );
  }

  for (final readOnly in [false, true]) {
    test('a page ending with an embed opens as written${readOnly ? ' (read-only)' : ''}', () {
      final controller = controllerFor(endsWithEmbed, readOnly: readOnly);
      expect(controller.document.last, isA<StoryEmbedNode>());
      expect(controller.toMarkdown(), endsWithEmbed);
      expect(controller.isDirty, isFalse);
    });
  }

  test('switching to editing adds nothing', () {
    final controller = controllerFor(endsWithEmbed, readOnly: true)..readOnly = false;
    expect(controller.document.last, isA<StoryEmbedNode>());
    expect(controller.isDirty, isFalse);
  });

  test('Enter right after a trailing embed starts one new line, which is kept', () {
    final controller = controllerFor(endsWithEmbed);
    caretAfterLast(controller);
    controller.editor.execute([InsertNewlineAtCaretRequest()]);
    expect(controller.document.nodeCount, 3);
    expect(controller.toMarkdown(), '$endsWithEmbed\n\n&nbsp;');
  });

  for (final (name, request) in [
    ('text', () => InsertPlainTextAtCaretRequest('Bye')),
    ('a character', () => InsertCharacterAtCaretRequest(character: 'B')),
  ]) {
    test('inserting $name right after a trailing embed starts a new line holding it', () {
      final controller = controllerFor(endsWithEmbed);
      caretAfterLast(controller);
      controller.editor.execute([request()]);
      final line = controller.document.last as ParagraphNode;
      expect(controller.toMarkdown(), '$endsWithEmbed\n\n${line.text.toPlainText()}');
      expect(line.text.toPlainText(), isNotEmpty);
      expect(controller.selection.value?.extent.nodeId, line.id);
    });
  }

  test('a divider inserted at the end of a line adds no empty line either', () {
    final controller = controllerFor('Hello\n\nWorld');
    controller.composer.setSelectionWithReason(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: controller.document.first.id,
          nodePosition: const TextNodePosition(offset: 5),
        ),
      ),
    );
    controller.actions.insertHorizontalRule();
    expect(controller.toMarkdown(), 'Hello\n\n---\n\nWorld');
  });

  group('blank lines are kept wherever they are', () {
    void addLine(StoryEditorController controller, int index) {
      controller.editor.execute([
        InsertNodeAtIndexRequest(
          nodeIndex: index,
          newNode: ParagraphNode(id: Editor.createNodeId(), text: AttributedText()),
        ),
      ]);
    }

    for (final (where, index, expected) in [
      ('top', 0, '&nbsp;\n\na\n\nb'),
      ('middle', 1, 'a\n\n&nbsp;\n\nb'),
      ('bottom', 2, 'a\n\nb\n\n&nbsp;'),
    ]) {
      test(where, () {
        final controller = controllerFor('a\n\nb');
        addLine(controller, index);
        expect(controller.toMarkdown(), expected);
        expect(controller.isDirty, isTrue);

        final reopened = controllerFor(expected, readOnly: true);
        expect(reopened.document.nodeCount, 3);
      });
    }
  });

  group('Enter at the start of a heading or quote', () {
    for (final markdown in ['# Title\n\nbody', '> quoted\n\nbody']) {
      test('adds a plain empty line above it, the block unchanged: $markdown', () {
        final controller = controllerFor(markdown);
        final first = controller.document.first;
        controller.composer.setSelectionWithReason(
          DocumentSelection.collapsed(
            position: DocumentPosition(nodeId: first.id, nodePosition: const TextNodePosition(offset: 0)),
          ),
        );
        controller.editor.execute([InsertNewlineAtCaretRequest()]);

        expect(controller.toMarkdown(), '&nbsp;\n\n$markdown');
        expect(controller.selection.value?.extent.nodeId, first.id, reason: 'the caret stays on the block');
      });
    }

    test('in the middle of a heading, Enter still splits it as usual', () {
      final controller = controllerFor('# Title');
      final first = controller.document.first;
      controller.composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(nodeId: first.id, nodePosition: const TextNodePosition(offset: 2)),
        ),
      );
      controller.editor.execute([InsertNewlineAtCaretRequest()]);
      expect(controller.document.nodeCount, 2);
      expect(controller.toMarkdown(), startsWith('# Ti'));
    });
  });
}
