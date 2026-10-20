import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// Caret movement from a toolbar (e.g. arrow buttons on a phone, where there are no arrow keys).
void main() {
  DocumentPosition? caret(StoryEditorController controller) => controller.selection.value?.extent;

  test('placeCaretAtEnd puts the caret after the last character', () {
    final controller = controllerFor('One\n\nTwo');
    controller.actions.placeCaretAtEnd();
    expect(
      caret(controller),
      DocumentPosition(nodeId: nodeAt(controller, 1).id, nodePosition: const TextNodePosition(offset: 3)),
    );
  });

  test('moves one character, across blocks at their edges', () {
    final controller = controllerFor('ab\n\ncd');
    placeCaret(controller, 0, 1);

    controller.actions.moveCaret(forward: true);
    expect(caret(controller)!.nodePosition, const TextNodePosition(offset: 2));
    controller.actions.moveCaret(forward: true);
    expect(
      caret(controller),
      DocumentPosition(nodeId: nodeAt(controller, 1).id, nodePosition: const TextNodePosition(offset: 0)),
    );
    controller.actions.moveCaret(forward: false);
    expect(
      caret(controller),
      DocumentPosition(nodeId: nodeAt(controller, 0).id, nodePosition: const TextNodePosition(offset: 2)),
    );
  });

  test('never splits a character made of several code units', () {
    final controller = controllerFor('a👍🏽b');
    placeCaret(controller, 0, 1);
    controller.actions.moveCaret(forward: true);
    expect(caret(controller)!.nodePosition, const TextNodePosition(offset: 5));
    controller.actions.moveCaret(forward: false);
    expect(caret(controller)!.nodePosition, const TextNodePosition(offset: 1));
  });

  test('steps over an embed through both its edges', () {
    final controller = controllerFor('a\n\n<sp-sticker name="cat"></sp-sticker>\n\nb');
    placeCaret(controller, 0, 1);
    final embedId = nodeAt(controller, 1).id;

    controller.actions.moveCaret(forward: true);
    expect(
      caret(controller),
      DocumentPosition(nodeId: embedId, nodePosition: const UpstreamDownstreamNodePosition.upstream()),
    );
    controller.actions.moveCaret(forward: true);
    expect(
      caret(controller),
      DocumentPosition(nodeId: embedId, nodePosition: const UpstreamDownstreamNodePosition.downstream()),
    );
    controller.actions.moveCaret(forward: true);
    expect(caret(controller)!.nodeId, nodeAt(controller, 2).id);
  });

  test('stops at the document edges', () {
    final controller = controllerFor('ab');
    placeCaret(controller, 0, 0);
    expect(controller.actions.canMoveCaret(forward: false), isFalse);
    expect(controller.actions.canMoveCaret(forward: true), isTrue);
    controller.actions.moveCaret(forward: false);
    expect(caret(controller)!.nodePosition, const TextNodePosition(offset: 0));

    placeCaret(controller, 0, 2);
    expect(controller.actions.canMoveCaret(forward: true), isFalse);
  });

  test('an expanded selection collapses to its end or start', () {
    final controller = controllerFor('abcd');
    selectText(controller, 0, 3, 0, 1);
    controller.actions.moveCaret(forward: true);
    expect(controller.selection.value!.isCollapsed, isTrue);
    expect(caret(controller)!.nodePosition, const TextNodePosition(offset: 3));

    selectText(controller, 0, 1, 0, 3);
    controller.actions.moveCaret(forward: false);
    expect(caret(controller)!.nodePosition, const TextNodePosition(offset: 1));
  });

  test('without a selection, nothing moves', () {
    final controller = controllerFor('ab');
    expect(controller.actions.canMoveCaret(forward: true), isFalse);
    controller.actions.moveCaret(forward: true);
    expect(controller.selection.value, isNull);
  });
}
