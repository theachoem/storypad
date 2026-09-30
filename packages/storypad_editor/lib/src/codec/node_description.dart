import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';

/// A readable one-line description of [node], for failure messages.
String describeNode(DocumentNode node) {
  final String detail;
  switch (node) {
    case ParagraphNode():
      detail = '${_blockType(node).id} align=${_align(node)} indent=${node.indent} "${node.text.toPlainText()}"';
    case ListItemNode():
      detail = '${node.type.name} align=${_align(node)} indent=${node.indent} "${node.text.toPlainText()}"';
    case TaskNode():
      detail =
          '[${node.isComplete ? 'x' : ' '}] align=${_align(node)} indent=${node.indent} "${node.text.toPlainText()}"';
    case StoryEmbedNode():
      detail = '${node.type}: ${node.value}';
    default:
      detail = '';
  }
  return '${node.runtimeType}($detail)';
}

Attribution _blockType(DocumentNode node) => node.getMetadataValue(NodeMetadata.blockType) ?? paragraphAttribution;

String _align(DocumentNode node) => node.getMetadataValue(TextNodeMetadata.textAlign) ?? 'left';
