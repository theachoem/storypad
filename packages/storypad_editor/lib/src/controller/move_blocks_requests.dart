import 'package:super_editor/super_editor.dart';

/// The requests that move a run of consecutive blocks together: [nodeIds] (in document order) end up starting at
/// [newIndex] among the *other* blocks -- 0 puts them first, the count of other blocks puts them last.
///
/// Plain `MoveNodeRequest`s, so any editor handles them; execute them in one `Editor.execute` for one undo step.
List<EditRequest> moveBlocksRequests(Document document, List<String> nodeIds, int newIndex) {
  final moving = nodeIds.toSet();
  if (moving.isEmpty || moving.any((id) => document.getNodeById(id) == null)) return const [];

  final current = [for (final node in document) node.id];
  final others = [
    for (final id in current)
      if (!moving.contains(id)) id,
  ];
  final at = newIndex.clamp(0, others.length);
  final target = [...others.sublist(0, at), ...nodeIds, ...others.sublist(at)];

  // Put each block at its final index in turn (everything before it is already in place), tracking the order as the
  // requests will leave it.
  final requests = <EditRequest>[];
  for (var index = 0; index < target.length; index++) {
    if (current[index] == target[index]) continue;
    requests.add(MoveNodeRequest(nodeId: target[index], newIndex: index));
    current
      ..remove(target[index])
      ..insert(index, target[index]);
  }
  return requests;
}
