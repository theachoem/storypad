import 'package:flutter/services.dart' show TextPosition;
import 'package:super_editor/super_editor.dart';

/// The edit that inserts [block] (an embed, a divider) at [position] -- the caret -- in [document]; at the end of the
/// document when there's no position. No empty line is ever added for the caret.
///
/// - A plain empty line takes the block in its place: the block goes before it, the caret stays on the line.
/// - At the start of a line, the block goes before it; the caret stays at the line's start.
/// - At the end of a line -- an empty heading or quote included, which keeps its place -- or on any other block (a list
///   item, a task, another embed), it goes after it, the caret right after the block.
/// - Inside a paragraph, it splits it there; both halves keep the line's style (heading, quote, alignment, indent), the
///   caret at the start of the second half.
List<EditRequest> insertBlockRequests(Document document, DocumentPosition? position, DocumentNode block) {
  final target = position == null ? null : document.getNodeById(position.nodeId);
  final nodePosition = position?.nodePosition;

  if (target is ParagraphNode && nodePosition is TextNodePosition) {
    final Object? blockType = target.getMetadataValue(NodeMetadata.blockType);
    final isPlainEmptyLine = target.text.isEmpty && (blockType == null || blockType == paragraphAttribution);
    final offset = nodePosition.offset;

    if (isPlainEmptyLine || (offset <= 0 && target.text.isNotEmpty)) {
      return [
        InsertNodeBeforeNodeRequest(existingNodeId: target.id, newNode: block),
        ..._placeCaret(DocumentPosition(nodeId: target.id, nodePosition: const TextNodePosition(offset: 0))),
      ];
    }

    if (offset < target.text.length) {
      final tailId = Editor.createNodeId();
      return [
        SplitParagraphRequest(
          nodeId: target.id,
          splitPosition: TextPosition(offset: offset),
          newNodeId: tailId,
          replicateExistingMetadata: true,
        ),
        InsertNodeAfterNodeRequest(existingNodeId: target.id, newNode: block),
        ..._placeCaret(DocumentPosition(nodeId: tailId, nodePosition: const TextNodePosition(offset: 0))),
      ];
    }
  }

  return [
    InsertNodeAfterNodeRequest(existingNodeId: target?.id ?? document.last.id, newNode: block),
    ..._placeCaret(DocumentPosition(nodeId: block.id, nodePosition: const UpstreamDownstreamNodePosition.downstream())),
  ];
}

/// Places the caret, and clears the composing region (the caret moved away from what the IME was composing).
List<EditRequest> _placeCaret(DocumentPosition position) => [
  ChangeSelectionRequest(
    DocumentSelection.collapsed(position: position),
    SelectionChangeType.insertContent,
    SelectionReason.contentChange,
  ),
  ChangeComposingRegionRequest(null),
];
