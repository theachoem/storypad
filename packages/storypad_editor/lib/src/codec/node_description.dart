import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';

/// A readable one-line description of a document node, for failure messages: its type, block type, alignment, indent
/// and text (or an embed's value).
class NodeDescription {
  const NodeDescription(this.node);

  final DocumentNode node;

  String describe() {
    final node = this.node;
    final String detail;
    switch (node) {
      case ParagraphNode():
        detail = '${_blockType().id} align=${_align()} indent=${node.indent} "${node.text.toPlainText()}"';
      case ListItemNode():
        detail = '${node.type.name} align=${_align()} indent=${node.indent} "${node.text.toPlainText()}"';
      case TaskNode():
        detail =
            '[${node.isComplete ? 'x' : ' '}] align=${_align()} indent=${node.indent} "${node.text.toPlainText()}"';
      case StoryEmbedNode():
        detail = '${node.type}: ${node.value}';
      default:
        detail = '';
    }
    return '${node.runtimeType}($detail)';
  }

  Attribution _blockType() => node.getMetadataValue(NodeMetadata.blockType) ?? paragraphAttribution;

  String _align() => node.getMetadataValue(TextNodeMetadata.textAlign) ?? 'left';
}
