import 'package:super_editor/super_editor.dart';

/// Moving a run of consecutive blocks together, as plain `MoveNodeRequest`s.
class MoveBlocks {
  const MoveBlocks._();

  /// The requests that move a run of consecutive blocks together: [nodeIds] (in document order) end up starting at
  /// [newIndex] among the *other* blocks -- 0 puts them first, the count of other blocks puts them last.
  ///
  /// Plain `MoveNodeRequest`s, one per moved block (the blocks in between are never moved, however far the run goes),
  /// so any editor handles them; execute them in one `Editor.execute` for one undo step.
  static List<EditRequest> requests(Document document, List<String> nodeIds, int newIndex) {
    if (nodeIds.isEmpty || nodeIds.any((id) => document.getNodeById(id) == null)) return const [];

    final from = document.getNodeIndexById(nodeIds.first);
    assert(
      nodeIds.indexed.every((entry) => document.getNodeIndexById(entry.$2) == from + entry.$1),
      'MoveBlocks.requests takes a run of consecutive blocks, in document order: $nodeIds',
    );
    // The run's first block ends up at `to`: there are `to` other blocks before it.
    final to = newIndex.clamp(0, document.nodeCount - nodeIds.length);
    if (to == from) return const [];

    // Each block straight to its final index. Moving up, the first goes first: the run's other blocks are below the
    // ones moved so far, so they keep their indices; moving down, the last goes first, for the same reason.
    final order = to < from ? nodeIds.indexed : nodeIds.indexed.toList().reversed;
    return [for (final (offset, id) in order) MoveNodeRequest(nodeId: id, newIndex: to + offset)];
  }
}
