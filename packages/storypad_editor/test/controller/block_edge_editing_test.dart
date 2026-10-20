import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';
import '../support/test_embeds.dart';

/// Editing around blocks: the editor never adds a line of its own -- what's on the page is what's written, blank lines
/// included, wherever they are. Next to an embed or divider, typing, pasting or Enter starts a new line there.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sticker = '<sp-sticker name="cat"></sp-sticker>';
  const endsWithEmbed = 'Hello\n\n$sticker';

  void caretAtEdgeOf(StoryEditorController controller, DocumentNode node, {bool before = false}) {
    controller.composer.setSelectionWithReason(
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: node.id,
          nodePosition: before
              ? const UpstreamDownstreamNodePosition.upstream()
              : const UpstreamDownstreamNodePosition.downstream(),
        ),
      ),
    );
  }

  test('Enter right after a trailing embed starts one new line, which is kept', () {
    final controller = controllerFor(endsWithEmbed);
    caretAtEdgeOf(controller, controller.document.last);
    controller.editor.execute([InsertNewlineAtCaretRequest()]);
    expect(controller.document.nodeCount, 3);
    expect(controller.toMarkdown(), '$endsWithEmbed\n\n&nbsp;');
  });

  group('text next to an embed starts a new line holding it', () {
    for (final (name, request) in [
      ('text', () => InsertPlainTextAtCaretRequest('Bye')),
      ('a character', () => InsertCharacterAtCaretRequest(character: 'B')),
    ]) {
      test('$name after it', () {
        final controller = controllerFor(endsWithEmbed);
        caretAtEdgeOf(controller, controller.document.last);
        controller.editor.execute([request()]);
        final line = controller.document.last as ParagraphNode;
        expect(line.text.toPlainText(), isNotEmpty);
        expect(controller.toMarkdown(), '$endsWithEmbed\n\n${line.text.toPlainText()}');
        expect(controller.selection.value?.extent.nodeId, line.id);
      });
    }

    test('text before it, at its upstream edge', () {
      final controller = controllerFor(sticker);
      caretAtEdgeOf(controller, controller.document.first, before: true);
      controller.editor.execute([InsertPlainTextAtCaretRequest('Hi')]);
      expect(controller.toMarkdown(), 'Hi\n\n$sticker');
      expect(controller.selection.value?.extent.nodeId, controller.document.first.id);
    });

    test('a character typed after toggling Bold there is bold', () {
      final controller = controllerFor(endsWithEmbed);
      caretAtEdgeOf(controller, controller.document.last);
      controller.composer.preferences.addStyle(boldAttribution);
      controller.editor.execute([InsertCharacterAtCaretRequest(character: 'B')]);
      expect(controller.toMarkdown(), '$endsWithEmbed\n\n**B**');
    });

    for (final (where, markdown, before, expected) in [
      ('after a trailing embed', endsWithEmbed, false, '$endsWithEmbed\n\nBye'),
      ('before a leading embed', sticker, true, 'Bye\n\n$sticker'),
      ('after a divider', 'a\n\n---', false, 'a\n\n---\n\nBye'),
    ]) {
      test('pasting $where', () {
        final controller = controllerFor(markdown);
        final block = before ? controller.document.first : controller.document.last;
        caretAtEdgeOf(controller, block, before: before);
        controller.editor.execute([
          PasteEditorRequest(content: 'Bye', pastePosition: controller.selection.value!.extent),
        ]);
        expect(controller.toMarkdown(), expected);

        controller.actions.undo();
        expect(controller.toMarkdown(), markdown);
      });
    }
  });

  group('inserting an embed or divider', () {
    for (final (name, markdown, expected) in [
      ('a quote', '> Hello', '> He\n\n$sticker\n\n> llo'),
      ('a heading', '## Hello', '## He\n\n$sticker\n\n## llo'),
      (
        'a centered paragraph',
        '<div style="text-align:center">\n\nHello\n\n</div>',
        '<div style="text-align:center">\n\nHe\n\n</div>\n\n$sticker\n\n<div style="text-align:center">\n\nllo\n\n</div>',
      ),
    ]) {
      test('in the middle of $name splits it, both halves keeping its style', () {
        final controller = controllerFor(markdown);
        placeCaret(controller, 0, 2);
        controller.insertEmbed(const StickerEmbedCodec(), 'cat');
        expect(controller.toMarkdown(), expected);
        expect(controller.selection.value?.extent.nodeId, controller.document.last.id);
      });
    }

    test('a divider in a list item goes after it', () {
      final controller = controllerFor('- one\n- two');
      placeCaret(controller, 0, 1);
      controller.actions.insertHorizontalRule();
      expect(controller.toMarkdown(), '- one\n\n---\n\n- two');
    });

    test('a divider on an empty heading goes after it: the heading keeps its place', () {
      final controller = controllerFor('# \n\nbody');
      placeCaret(controller, 0, 0);
      controller.actions.insertHorizontalRule();
      expect(controller.document.first, isA<ParagraphNode>());
      expect(controller.document.getNodeAt(1), isA<HorizontalRuleNode>());
    });

    test('a divider at the end of a line adds no empty line', () {
      final controller = controllerFor('Hello\n\nWorld');
      placeCaret(controller, 0, 5);
      controller.actions.insertHorizontalRule();
      expect(controller.toMarkdown(), 'Hello\n\n---\n\nWorld');
      expect(controller.selection.value?.extent.nodePosition, const UpstreamDownstreamNodePosition.downstream());
    });
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
        placeCaret(controller, 0, 0);
        controller.editor.execute([InsertNewlineAtCaretRequest()]);

        expect(controller.toMarkdown(), '&nbsp;\n\n$markdown');
        expect(controller.selection.value?.extent.nodeId, first.id, reason: 'the caret stays on the block');
      });
    }

    test('in the middle of a heading, Enter still splits it as usual', () {
      final controller = controllerFor('# Title');
      placeCaret(controller, 0, 2);
      controller.editor.execute([InsertNewlineAtCaretRequest()]);
      expect(controller.document.nodeCount, 2);
      expect(controller.toMarkdown(), startsWith('# Ti'));
    });
  });
}
