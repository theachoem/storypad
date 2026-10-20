import 'dart:ui' show TextAlign;

import 'package:super_editor/super_editor.dart';

import 'change_text_alignment_request.dart';
import '../document/text_alignment.dart';

class ChangeTextAlignmentCommand extends EditCommand {
  const ChangeTextAlignmentCommand(this.nodeId, this.alignment);

  final String nodeId;
  final TextAlign alignment;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final node = document.getNodeById(nodeId);
    if (node is! TextNode) return;

    final name = TextAlignment.name(alignment);
    if (node.getMetadataValue(TextNodeMetadata.textAlign) == name) return;

    document.replaceNodeById(node.id, node.copyWithAddedMetadata({TextNodeMetadata.textAlign: name}));
    executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
  }

  /// Turns a [ChangeTextAlignmentRequest] into this command; register with the editor's request handlers.
  static EditCommand? handler(Editor editor, EditRequest request) =>
      request is ChangeTextAlignmentRequest ? ChangeTextAlignmentCommand(request.nodeId, request.alignment) : null;
}
