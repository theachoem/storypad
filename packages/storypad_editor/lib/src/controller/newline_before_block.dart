import 'package:super_editor/super_editor.dart';

import '../markdown/markdown_format.dart';

/// Enter at the very start of a non-empty heading or quote adds a plain empty line above it, at the block's indent, and
/// the caret stays on the block -- as in most editors. super_editor's default splits the block there instead, leaving
/// an *empty heading or quote* above and pushing the text down (so a page's heading title stopped being first).
EditCommand? newlineBeforeBlockHandler(Editor editor, EditRequest request) {
  if (request is! InsertNewlineAtCaretRequest) return null;

  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;

  final position = selection.extent;
  final node = editor.document.getNodeById(position.nodeId);
  final nodePosition = position.nodePosition;
  if (node is! ParagraphNode || node.text.isEmpty) return null;
  if (nodePosition is! TextNodePosition || nodePosition.offset != 0) return null;

  final Attribution? blockType = node.getMetadataValue(NodeMetadata.blockType);
  if (headerLevel(blockType) == null && blockType != blockquoteAttribution) return null;

  return InsertNodeBeforeNodeCommand(
    existingNodeId: node.id,
    newNode: ParagraphNode(id: request.newNodeId, text: AttributedText(), indent: node.indent),
  );
}
