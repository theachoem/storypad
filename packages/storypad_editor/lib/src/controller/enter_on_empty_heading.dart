import 'package:super_editor/super_editor.dart';

import '../document/heading.dart';

/// Enter on an empty heading turns it into a plain line, in place -- the writer is skipping it (e.g. an empty page's
/// title line, where they go straight to the body), so no empty heading is left behind. Like Enter on an empty list
/// item leaving the list.
class EnterOnEmptyHeading {
  const EnterOnEmptyHeading._();

  static EditCommand? handler(Editor editor, EditRequest request) {
    if (request is! InsertNewlineAtCaretRequest) return null;

    final selection = editor.composer.selection;
    if (selection == null || !selection.isCollapsed) return null;

    final node = editor.document.getNodeById(selection.extent.nodeId);
    if (node is! ParagraphNode || node.text.isNotEmpty) return null;
    if (Heading.levelOf(node.getMetadataValue(NodeMetadata.blockType)) == null) return null;

    return ChangeParagraphBlockTypeCommand(nodeId: node.id, blockType: null);
  }
}
