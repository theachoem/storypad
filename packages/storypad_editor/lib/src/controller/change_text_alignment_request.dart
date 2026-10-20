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
