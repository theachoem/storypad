import 'package:super_editor/super_editor.dart';

/// A node's block type (`paragraph`, `header1`, `blockquote`, an embed's type, …), as its metadata holds it.
class BlockType {
  const BlockType._();

  /// The block type a node holds: its block type metadata's id, e.g. `paragraph`, `header1`,
  /// `blockquote`, `code`, `listItem`, `task`, `horizontalRule`, or an embed's type.
  static String? of(DocumentNode node) {
    final Object? blockType = node.getMetadataValue(NodeMetadata.blockType);
    return blockType is Attribution ? blockType.id : null;
  }
}
