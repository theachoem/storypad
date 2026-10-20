import 'package:super_editor/super_editor.dart';

/// Replaces ranges of text with `transform(text)` in place, keeping their formatting, as one undoable edit -- e.g. to
/// upper or lower case. The selection keeps covering the same text.
class TransformTextRequest implements EditRequest {
  const TransformTextRequest(this.ranges, this.transform);

  /// `[start, end)` ranges within text blocks, at most one per block.
  final List<({String nodeId, int start, int end})> ranges;
  final String Function(String text) transform;
}
