import 'package:super_editor/super_editor.dart';

/// Replaces ranges of text with `transform(text)` in place, keeping their formatting, as one undoable edit -- e.g. to
/// upper or lower case. The selection keeps covering the same text.
class TransformTextRequest implements EditRequest {
  const TransformTextRequest(this.ranges, this.transform);

  /// `[start, end)` ranges within text blocks, at most one per block.
  final List<({String nodeId, int start, int end})> ranges;
  final String Function(String text) transform;
}

class TransformTextCommand extends EditCommand {
  const TransformTextCommand(this.ranges, this.transform);

  final List<({String nodeId, int start, int end})> ranges;
  final String Function(String text) transform;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final changes = <EditEvent>[];
    // How much each block's range grew or shrank, and where it ended, to move the selection with the text.
    final shifts = <String, ({int end, int delta})>{};

    for (final range in ranges) {
      final node = document.getNodeById(range.nodeId);
      if (node is! TextNode) continue;

      final text = node.text;
      final start = range.start.clamp(0, text.length);
      final end = range.end.clamp(start, text.length);
      if (start == end) continue;

      final original = text.copyText(start, end);
      final transformed = transform(original.toPlainText());
      if (transformed == original.toPlainText()) continue;

      final AttributedText replacement;
      if (transformed.length == original.length) {
        replacement = AttributedText(transformed, original.spans.copy());
      } else {
        // The formatting can't map character by character: the whole range takes its first character's.
        replacement = AttributedText(transformed);
        if (transformed.isNotEmpty) {
          for (final attribution in original.getAllAttributionsAt(0)) {
            replacement.addAttribution(attribution, SpanRange(0, transformed.length - 1));
          }
        }
      }

      final updated = text.copyText(0, start).copyAndAppend(replacement).copyAndAppend(text.copyText(end));
      document.replaceNodeById(node.id, node.copyTextNodeWith(text: updated));
      changes.add(DocumentEdit(NodeChangeEvent(node.id)));
      shifts[node.id] = (end: end, delta: transformed.length - original.length);
    }
    if (changes.isEmpty) return;
    executor.logChanges(changes);

    final composer = context.find<MutableDocumentComposer>(Editor.composerKey);
    final selection = composer.selection;
    if (selection == null || shifts.values.every((shift) => shift.delta == 0)) return;

    DocumentPosition shifted(DocumentPosition position) {
      final shift = shifts[position.nodeId];
      final nodePosition = position.nodePosition;
      if (shift == null || nodePosition is! TextNodePosition || nodePosition.offset < shift.end) return position;
      return position.copyWith(nodePosition: TextNodePosition(offset: nodePosition.offset + shift.delta));
    }

    executor.executeCommand(
      ChangeSelectionCommand(
        DocumentSelection(base: shifted(selection.base), extent: shifted(selection.extent)),
        SelectionChangeType.alteredContent,
        SelectionReason.contentChange,
      ),
    );
  }
}

EditCommand? transformTextHandler(Editor editor, EditRequest request) =>
    request is TransformTextRequest ? TransformTextCommand(request.ranges, request.transform) : null;
