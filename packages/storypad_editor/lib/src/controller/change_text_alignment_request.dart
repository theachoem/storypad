import 'dart:ui' show TextAlign;

import 'package:super_editor/super_editor.dart';

/// Aligns a text block -- a paragraph, heading, quote, list item or task -- as an undoable edit. super_editor's own
/// `ChangeParagraphAlignmentRequest` only takes paragraphs, but a Quill story can align any line.
///
/// Alignment lives in the node's `textAlign` metadata (`left`, `center`, `right` or `justify`), like super_editor's.
class ChangeTextAlignmentRequest implements EditRequest {
  const ChangeTextAlignmentRequest(this.nodeId, this.alignment);

  final String nodeId;
  final TextAlign alignment;
}

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

    final name = textAlignName(alignment);
    if (node.getMetadataValue(TextNodeMetadata.textAlign) == name) return;

    document.replaceNodeById(node.id, node.copyWithAddedMetadata({TextNodeMetadata.textAlign: name}));
    executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
  }
}

EditCommand? changeTextAlignmentHandler(Editor editor, EditRequest request) =>
    request is ChangeTextAlignmentRequest ? ChangeTextAlignmentCommand(request.nodeId, request.alignment) : null;

/// The `textAlign` metadata value for [alignment].
String textAlignName(TextAlign alignment) => switch (alignment) {
  TextAlign.center => 'center',
  TextAlign.right || TextAlign.end => 'right',
  TextAlign.justify => 'justify',
  TextAlign.left || TextAlign.start => 'left',
};

/// The alignment in [node]'s `textAlign` metadata, or `null` if it has none (or an unknown one).
TextAlign? textAlignOf(DocumentNode node) => switch (node.getMetadataValue(TextNodeMetadata.textAlign)) {
  'left' => TextAlign.left,
  'center' => TextAlign.center,
  'right' => TextAlign.right,
  'justify' => TextAlign.justify,
  _ => null,
};
