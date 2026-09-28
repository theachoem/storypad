import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/src/controller/move_blocks_requests.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Moving the selected blocks up/down (e.g. toolbar buttons on a phone), and moving a run of blocks anywhere.
void main() {
  test('moves every block the selection touches, together, keeping the selection', () {
    final controller = controllerFor('a\n\nb\n\nc\n\nd');
    selectText(controller, 1, 0, 2, 1);

    controller.actions.moveSelectedBlocks(up: true);
    expect(controller.toMarkdown(), 'b\n\nc\n\na\n\nd');
    expect(controller.actions.selectedBlockIds, [nodeAt(controller, 0).id, nodeAt(controller, 1).id]);

    controller.actions.moveSelectedBlocks(up: false);
    controller.actions.moveSelectedBlocks(up: false);
    expect(controller.toMarkdown(), 'a\n\nd\n\nb\n\nc');
  });

  test('a caret moves its own block; embeds and lists move too', () {
    final controller = controllerFor('- one\n- two\n\n<sp-sticker name="cat"></sp-sticker>\n\nend');
    placeCaret(controller, 1, 0);
    controller.actions.moveSelectedBlocks(up: false);
    expect(controller.toMarkdown(), '- one\n\n<sp-sticker name="cat"></sp-sticker>\n\n- two\n\nend');
  });

  test('not past the document edges; one undo step each', () {
    final controller = controllerFor('a\n\nb\n\nc');
    selectText(controller, 0, 0, 1, 1);
    expect(controller.actions.canMoveSelectedBlocks(up: true), isFalse);
    expect(controller.actions.canMoveSelectedBlocks(up: false), isTrue);

    controller.actions.moveSelectedBlocks(up: true);
    expect(controller.toMarkdown(), 'a\n\nb\n\nc');

    controller.actions.moveSelectedBlocks(up: false);
    expect(controller.toMarkdown(), 'c\n\na\n\nb');
    expect(controller.actions.canMoveSelectedBlocks(up: false), isFalse);

    controller.actions.undo();
    expect(controller.toMarkdown(), 'a\n\nb\n\nc');
  });

  test('without a selection, nothing moves', () {
    final controller = controllerFor('a\n\nb');
    expect(controller.actions.canMoveSelectedBlocks(up: false), isFalse);
    controller.actions.moveSelectedBlocks(up: false);
    expect(controller.toMarkdown(), 'a\n\nb');
  });

  test('moveBlocksRequests: any run to any index among the other blocks', () {
    for (var index = 0; index <= 3; index++) {
      final document = MutableDocument(
        nodes: [
          for (final id in ['a', 'b', 'c', 'd', 'e']) ParagraphNode(id: id, text: AttributedText(id)),
        ],
      );
      final editor = createDefaultDocumentEditor(document: document, composer: MutableDocumentComposer());
      editor.execute(moveBlocksRequests(document, ['b', 'c'], index));

      final others = ['a', 'd', 'e'];
      expect(
        [for (final node in document) node.id],
        [...others.sublist(0, index), 'b', 'c', ...others.sublist(index)],
        reason: 'index $index',
      );
    }
  });
}
