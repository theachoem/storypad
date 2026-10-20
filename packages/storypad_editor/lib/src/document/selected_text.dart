import 'package:super_editor/super_editor.dart';

/// The text a selection covers.
class SelectedText {
  const SelectedText._();

  /// Serializes the content spanned by [selection] to plain text.
  ///
  /// This mirrors `CommonEditorOperations`'s private `_textInSelection`, which
  /// backs `copy()`/`cut()`. It's duplicated here (using only the same public
  /// [Document]/[DocumentNode] APIs that method itself uses) because both the
  /// native macOS Services menu and the Android Process Text actions need the
  /// selected text up front, without going through the system clipboard — using
  /// the clipboard would mean silently overwriting whatever the user last
  /// copied, just from right-clicking or long-pressing.
  static String plainText({required Document document, required DocumentSelection selection}) {
    final selectedNodes = document.getNodesInside(selection.base, selection.extent);

    final buffer = StringBuffer();
    for (int i = 0; i < selectedNodes.length; ++i) {
      final selectedNode = selectedNodes[i];
      final NodeSelection nodeSelection;

      if (i == 0) {
        // This is the first node and it may be partially selected.
        final baseSelectionPosition = selectedNode.id == selection.base.nodeId
            ? selection.base.nodePosition
            : selection.extent.nodePosition;

        final extentSelectionPosition = selectedNodes.length > 1
            ? selectedNode.endPosition
            : selection.extent.nodePosition;

        nodeSelection = selectedNode.computeSelection(base: baseSelectionPosition, extent: extentSelectionPosition);
      } else if (i == selectedNodes.length - 1) {
        // This is the last node and it may be partially selected.
        final nodePosition = selectedNode.id == selection.base.nodeId
            ? selection.base.nodePosition
            : selection.extent.nodePosition;

        nodeSelection = selectedNode.computeSelection(base: selectedNode.beginningPosition, extent: nodePosition);
      } else {
        // This node is fully selected. Copy the whole thing.
        nodeSelection = selectedNode.computeSelection(
          base: selectedNode.beginningPosition,
          extent: selectedNode.endPosition,
        );
      }

      final nodeContent = selectedNode.copyContent(nodeSelection);
      if (nodeContent != null) {
        buffer.write(nodeContent);
        if (i < selectedNodes.length - 1) {
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }
}
