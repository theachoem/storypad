import 'package:flutter/services.dart' show TextAffinity;
import 'package:super_editor/super_editor.dart';

/// Text inserted or pasted with the caret at the edge of a block that holds no text (an embed, a divider) starts a new
/// line there -- after it at its downstream edge, before it at its upstream edge -- holding the text, caret at its end.
/// super_editor's own commands only add the empty line (a typed character), nothing at all (plain text), or throw
/// (a paste).
///
/// Keyboard typing doesn't come through here: the IME path already starts a line first. These requests are the ones
/// code sends (e.g. inserting shared text), and pastes (Cmd+V, the context menus).
EditCommand? textAtBlockEdgeHandler(Editor editor, EditRequest request) {
  if (request is PasteEditorRequest) {
    if (request.content.isEmpty) return null;
    final edge = _blockEdge(editor, request.pastePosition);
    if (edge == null) return null;
    final line = ParagraphNode(id: Editor.createNodeId(), text: AttributedText());
    return _InsertLineAtBlockEdgeCommand(
      blockId: edge.blockId,
      before: edge.before,
      line: line,
      then: PasteEditorCommand(
        content: request.content,
        pastePosition: DocumentPosition(nodeId: line.id, nodePosition: const TextNodePosition(offset: 0)),
      ),
    );
  }

  final String text;
  final bool withComposerStyles;
  if (request is InsertPlainTextAtCaretRequest) {
    text = request.plainText;
    withComposerStyles = true;
  } else if (request is InsertCharacterAtCaretRequest) {
    text = request.character;
    withComposerStyles = !request.ignoreComposerAttributions;
  } else {
    return null;
  }
  if (text.isEmpty) return null;

  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final edge = _blockEdge(editor, selection.extent);
  if (edge == null) return null;

  // Styles toggled with the caret there (e.g. Bold) apply to the text, as they would in a line.
  final attributedText = AttributedText(text);
  if (withComposerStyles) {
    for (final attribution in editor.composer.preferences.currentAttributions) {
      attributedText.addAttribution(attribution, SpanRange(0, text.length - 1));
    }
  }
  final line = ParagraphNode(id: Editor.createNodeId(), text: attributedText);
  return _InsertLineAtBlockEdgeCommand(blockId: edge.blockId, before: edge.before, line: line);
}

/// The block [position] is at the edge of, if it's a block that holds no text.
({String blockId, bool before})? _blockEdge(Editor editor, DocumentPosition position) {
  final nodePosition = position.nodePosition;
  if (nodePosition is! UpstreamDownstreamNodePosition) return null;
  final node = editor.document.getNodeById(position.nodeId);
  if (node == null || node is TextNode) return null;
  return (blockId: node.id, before: nodePosition.affinity == TextAffinity.upstream);
}

class _InsertLineAtBlockEdgeCommand extends EditCommand {
  _InsertLineAtBlockEdgeCommand({required this.blockId, required this.before, required this.line, this.then});

  final String blockId;
  final bool before;
  final ParagraphNode line;

  /// Run once the line is in, instead of placing the caret at its end (a paste places it after what it pasted).
  final EditCommand? then;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    executor.executeCommand(
      before
          ? InsertNodeBeforeNodeCommand(existingNodeId: blockId, newNode: line)
          : InsertNodeAfterNodeCommand(existingNodeId: blockId, newNode: line),
    );

    final then = this.then;
    if (then != null) {
      executor.executeCommand(then);
      return;
    }
    executor.executeCommand(
      ChangeSelectionCommand(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: line.id,
            nodePosition: TextNodePosition(offset: line.text.length),
          ),
        ),
        SelectionChangeType.insertContent,
        SelectionReason.userInteraction,
      ),
    );
  }
}
