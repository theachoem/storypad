import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';
import '../support/test_embeds.dart';

const _sticker = StickerEmbedCodec();
const _gallery = GalleryEmbedCodec();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('insertEmbed', () {
    test('on an empty line: takes its place, the caret right after it -- no empty line left behind', () {
      for (final (markdown, expected) in [
        ('a\n\n&nbsp;\n\nb', 'a\n\n<sp-sticker name="cat"></sp-sticker>\n\nb'),
        ('a\n\n&nbsp;', 'a\n\n<sp-sticker name="cat"></sp-sticker>'),
        ('', '<sp-sticker name="cat"></sp-sticker>'),
      ]) {
        final controller = controllerFor(markdown);
        placeCaret(controller, markdown.isEmpty ? 0 : 1, 0);

        final id = controller.insertEmbed(_sticker, 'cat');

        expect(controller.toMarkdown(), expected, reason: markdown);
        expect(
          controller.selection.value!.extent,
          DocumentPosition(nodeId: id, nodePosition: const UpstreamDownstreamNodePosition.downstream()),
          reason: markdown,
        );
      }
    });

    test('on an empty line, then typing: the text goes on a new line after it', () {
      final controller = controllerFor('a\n\n&nbsp;');
      placeCaret(controller, 1, 0);
      controller.insertEmbed(_sticker, 'cat');

      controller.editor.execute([const InsertPlainTextAtCaretRequest('x')]);
      expect(controller.toMarkdown(), 'a\n\n<sp-sticker name="cat"></sp-sticker>\n\nx');
    });

    test('at the end of a paragraph: goes after it, the caret right after it -- no empty line added', () {
      for (final markdown in ['Hello', 'Hello\n\nWorld']) {
        final controller = controllerFor(markdown);
        placeCaret(controller, 0, 5);

        final id = controller.insertEmbed(_sticker, 'cat');

        expect(
          controller.toMarkdown(),
          markdown.replaceFirst('Hello', 'Hello\n\n<sp-sticker name="cat"></sp-sticker>'),
          reason: markdown,
        );
        expect(nodeAt(controller, 1).id, id);
        expect(
          controller.selection.value!.extent,
          DocumentPosition(nodeId: id, nodePosition: const UpstreamDownstreamNodePosition.downstream()),
        );
      }
    });

    test('mid-paragraph: splits it', () {
      final controller = controllerFor('Hello');
      placeCaret(controller, 0, 2);

      controller.insertEmbed(_sticker, 'cat');

      expect(controller.toMarkdown(), 'He\n\n<sp-sticker name="cat"></sp-sticker>\n\nllo');
    });

    test('in a list item: goes after it', () {
      final controller = controllerFor('- item');
      placeCaret(controller, 0, 2);

      controller.insertEmbed(_sticker, 'cat');

      expect(controller.toMarkdown(), '- item\n\n<sp-sticker name="cat"></sp-sticker>');
    });

    test('without a selection: at the last selection, else at the end', () {
      final controller = controllerFor('a\n\nb');
      controller.insertEmbed(_sticker, 'end');
      expect(controller.toMarkdown(), 'a\n\nb\n\n<sp-sticker name="end"></sp-sticker>');

      placeCaret(controller, 0, 1);
      controller.composer.clearSelection(); // e.g. a picker sheet took focus
      controller.insertEmbed(_sticker, 'here');
      // At the end of a paragraph it goes after it, and no empty line is added for the caret.
      expect(controller.toMarkdown(), startsWith('a\n\n<sp-sticker name="here"></sp-sticker>\n\nb'));
    });

    test('a stale last selection (text shortened since) is clamped, not a crash', () {
      final controller = controllerFor('Hello world');
      placeCaret(controller, 0, 11);
      controller.composer.clearSelection();
      controller.editor.execute([
        DeleteContentRequest(
          documentRange: DocumentRange(
            start: DocumentPosition(nodeId: nodeAt(controller, 0).id, nodePosition: const TextNodePosition(offset: 5)),
            end: DocumentPosition(nodeId: nodeAt(controller, 0).id, nodePosition: const TextNodePosition(offset: 11)),
          ),
        ),
      ]);
      controller.composer.clearSelection();

      controller.insertEmbed(_sticker, 'cat');
      expect(controller.toMarkdown(), 'Hello\n\n<sp-sticker name="cat"></sp-sticker>');
    });

    test('is undoable', () {
      final controller = controllerFor('Hello');
      placeCaret(controller, 0, 5);
      controller.insertEmbed(_sticker, 'cat');

      controller.actions.undo();
      expect(controller.toMarkdown(), 'Hello');
    });
  });

  group('updateEmbed', () {
    test('transforms the live value, so rapid updates compose (no stale snapshot)', () {
      final controller = controllerFor('<sp-sticker name="a"></sp-sticker>');
      final id = nodeAt(controller, 0).id;

      expect(controller.updateEmbed(_sticker, id, (v) => '$v!'), isTrue);
      expect(controller.updateEmbed(_sticker, id, (v) => '$v!'), isTrue);

      expect(controller.embedsOf(_sticker).single.$2, 'a!!');
    });

    test('returns false when unchanged, missing, or of another type', () {
      final controller = controllerFor('<sp-sticker name="a"></sp-sticker>');
      final id = nodeAt(controller, 0).id;
      final revision = controller.documentRevision.value;

      expect(controller.updateEmbed(_sticker, id, (v) => v), isFalse);
      expect(controller.updateEmbed(_sticker, 'nope', (v) => v), isFalse);
      expect(controller.updateEmbed(_gallery, id, (v) => v), isFalse);
      expect(controller.documentRevision.value, revision, reason: 'no empty edits');
    });

    test('is undoable, and keeps the node id', () {
      final controller = controllerFor('<sp-sticker name="a"></sp-sticker>');
      final id = nodeAt(controller, 0).id;

      controller.updateEmbed(_sticker, id, (_) => 'b');
      expect(nodeAt(controller, 0).id, id);
      expect(controller.toMarkdown(), '<sp-sticker name="b"></sp-sticker>');

      controller.actions.undo();
      expect(controller.toMarkdown(), '<sp-sticker name="a"></sp-sticker>');
    });
  });

  group('removeEmbed', () {
    test('removes it and moves the selection off it', () {
      final controller = controllerFor('a\n\n<sp-sticker name="x"></sp-sticker>\n\nb');
      final id = nodeAt(controller, 1).id;
      controller.composer.setSelectionWithReason(
        DocumentSelection.collapsed(
          position: DocumentPosition(nodeId: id, nodePosition: const UpstreamDownstreamNodePosition.downstream()),
        ),
      );

      expect(controller.removeEmbed(id), isTrue);

      expect(controller.toMarkdown(), 'a\n\nb');
      expect(controller.selection.value!.extent.nodeId, isNot(id));
    });

    test('never leaves the document empty', () {
      final controller = controllerFor('<sp-sticker name="x"></sp-sticker>'); // Just the embed.
      expect(controller.document.nodeCount, 1);

      controller.removeEmbed(nodeAt(controller, 0).id);
      expect(controller.document.nodeCount, 1);
      expect(nodeAt(controller, 0), isA<ParagraphNode>());
    });

    test('returns false for a non-embed', () {
      final controller = controllerFor('a');
      expect(controller.removeEmbed(nodeAt(controller, 0).id), isFalse);
    });
  });

  test('embedsOf lists an embed type in document order', () {
    final controller = controllerFor(
      '<sp-sticker name="a"></sp-sticker>\n\n![](x.jpg)\n\n<sp-sticker name="b"></sp-sticker>',
    );
    expect(controller.embedsOf(_sticker).map((e) => e.$2), ['a', 'b']);
    expect(controller.embedsOf(_gallery).single.$2, const GalleryValue(['x.jpg']));
  });
}
