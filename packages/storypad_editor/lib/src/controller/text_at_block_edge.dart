import 'package:flutter/services.dart' show TextAffinity;
import 'package:super_editor/super_editor.dart';

/// Text inserted with the caret at the edge of a block that holds no text (an embed, a divider) starts a new line
/// there -- after it at its downstream edge, before it at its upstream edge -- holding the text, caret at its end.
/// super_editor's own commands only add the empty line (a typed character) or nothing at all (plain text).
///
/// Keyboard typing doesn't come through here: the IME path already starts a line first. These requests are the ones
/// code sends (e.g. inserting shared text).
EditCommand? textAtBlockEdgeHandler(Editor editor, EditRequest request) {
  final String text;
  if (request is InsertPlainTextAtCaretRequest) {
    text = request.plainText;
  } else if (request is InsertCharacterAtCaretRequest) {
    text = request.character;
  } else {
    return null;
  }
  if (text.isEmpty) return null;

  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final position = selection.extent.nodePosition;
  if (position is! UpstreamDownstreamNodePosition) return null;
  final node = editor.document.getNodeById(selection.extent.nodeId);
  if (node == null || node is TextNode) return null;

  return _InsertLineAtBlockEdgeCommand(
    blockId: node.id,
    before: position.affinity == TextAffinity.upstream,
    line: ParagraphNode(id: Editor.createNodeId(), text: AttributedText(text)),
  );
}

class _InsertLineAtBlockEdgeCommand extends EditCommand {
  _InsertLineAtBlockEdgeCommand({required this.blockId, required this.before, required this.line});

  final String blockId;
  final bool before;
  final ParagraphNode line;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    executor
      ..executeCommand(
        before
            ? InsertNodeBeforeNodeCommand(existingNodeId: blockId, newNode: line)
            : InsertNodeAfterNodeCommand(existingNodeId: blockId, newNode: line),
      )
      ..executeCommand(
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
