import 'package:super_editor/super_editor.dart';

/// Nodes read from `lines[start, end)`.
class MarkdownBlock {
  MarkdownBlock(this.nodes, this.end);

  final List<DocumentNode> nodes;

  /// The index of the first line after the block.
  final int end;
}
