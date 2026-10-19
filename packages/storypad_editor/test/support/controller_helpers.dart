import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import 'test_embeds.dart';

/// A controller over [markdown] with the test embeds, disposed at the end of the test.
StoryEditorController controllerFor(String markdown, {bool readOnly = false}) {
  final controller = StoryEditorController(embeds: testEmbeds, markdown: markdown, readOnly: readOnly);
  addTearDown(controller.dispose);
  return controller;
}

DocumentNode nodeAt(StoryEditorController controller, int index) => controller.document.getNodeAt(index)!;

/// Places the caret at [offset] in text node [index].
void placeCaret(StoryEditorController controller, int index, int offset) {
  controller.composer.setSelectionWithReason(
    DocumentSelection.collapsed(
      position: DocumentPosition(
        nodeId: nodeAt(controller, index).id,
        nodePosition: TextNodePosition(offset: offset),
      ),
    ),
  );
}

/// Selects text from ([fromIndex], [fromOffset]) to ([toIndex], [toOffset]).
void selectText(StoryEditorController controller, int fromIndex, int fromOffset, int toIndex, int toOffset) {
  controller.composer.setSelectionWithReason(
    DocumentSelection(
      base: DocumentPosition(
        nodeId: nodeAt(controller, fromIndex).id,
        nodePosition: TextNodePosition(offset: fromOffset),
      ),
      extent: DocumentPosition(
        nodeId: nodeAt(controller, toIndex).id,
        nodePosition: TextNodePosition(offset: toOffset),
      ),
    ),
  );
}

/// Selects the whole of text node [index].
void selectNode(StoryEditorController controller, int index) {
  final node = nodeAt(controller, index) as TextNode;
  selectText(controller, index, 0, index, node.text.length);
}
