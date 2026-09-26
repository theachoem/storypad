import 'package:meta/meta.dart';
import 'package:super_editor/super_editor.dart';

/// The one document node every embed uses: a block holding an embed [type] and its app-defined [value].
///
/// Apps never subclass this or write their own node/view-model classes -- an embed is described entirely by its
/// [StoryEmbedCodec], and nodes are created through [StoryEmbedCodec.createNode] so [plainText] stays in sync with
/// [value].
///
/// The node's block type metadata is always `NamedAttribution(type)`, so apps can style an embed type with a
/// `BlockSelector(type)` stylesheet rule.
///
/// Deliberately not generic: super_editor compares nodes and view models by `runtimeType`, so a
/// `StoryEmbedNode<Media>` and a `StoryEmbedNode<dynamic>` copy of it would silently compare unequal. Typed access goes
/// through the embed instead (`embed.valueOf(node)`).
@immutable
final class StoryEmbedNode extends BlockNode {
  StoryEmbedNode({required this.id, required this.type, required this.value, this.plainText = '', super.metadata}) {
    initAddToMetadata({NodeMetadata.blockType: NamedAttribution(type)});
  }

  @override
  final String id;

  /// The embed type, matching [StoryEmbedCodec.type].
  final String type;

  /// The embed's value. Must have value equality (`==`/`hashCode`), which is how edits are detected and documents
  /// compared.
  final Object value;

  /// [value] as plain text (from [StoryEmbedCodec.toPlainText]), used when the node is copied to the clipboard or
  /// read as text. Derived from [value], so it's excluded from equality.
  final String plainText;

  /// A copy with a new [value] (and its matching [plainText]), keeping id and metadata.
  StoryEmbedNode copyWithValue(Object value, {required String plainText}) {
    return StoryEmbedNode(id: id, type: type, value: value, plainText: plainText, metadata: metadata);
  }

  /// Returns [plainText] for a non-collapsed selection of this node, otherwise `null` (so nothing is copied). Never
  /// throws, unlike stock block nodes, whose throw on an unexpected selection type can crash a copy.
  @override
  String? copyContent(NodeSelection selection) {
    if (selection is! UpstreamDownstreamNodeSelection || selection.isCollapsed) return null;
    return plainText.isEmpty ? null : plainText;
  }

  /// Same embed type and equal value. Ignores id and metadata, like stock block nodes.
  @override
  bool hasEquivalentContent(DocumentNode other) =>
      other is StoryEmbedNode && type == other.type && value == other.value;

  @override
  StoryEmbedNode copyWithAddedMetadata(Map<String, dynamic> newProperties) {
    return StoryEmbedNode(
      id: id,
      type: type,
      value: value,
      plainText: plainText,
      metadata: {...metadata, ...newProperties},
    );
  }

  @override
  StoryEmbedNode copyAndReplaceMetadata(Map<String, dynamic> newMetadata) {
    return StoryEmbedNode(id: id, type: type, value: value, plainText: plainText, metadata: newMetadata);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StoryEmbedNode && id == other.id && type == other.type && value == other.value;

  @override
  int get hashCode => Object.hash(id, type, value);

  @override
  String toString() => 'StoryEmbedNode($id, $type: $value)';
}
