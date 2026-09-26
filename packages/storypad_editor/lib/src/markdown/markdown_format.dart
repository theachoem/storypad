import 'package:super_editor/super_editor.dart';

/// Constants and helpers shared by the Markdown writer and reader, which must agree on the format exactly.

/// The line written for an empty paragraph. Also how many Markdown users write an intentional blank line.
const emptyParagraphMarker = '&nbsp;';

/// Spaces per list/task nesting level.
const listIndentWidth = 4;

/// The deepest indent the format writes or reads, for lists, tasks and paragraphs. Also bounds how much work a
/// malformed document (e.g. a huge indent) can cause.
const maxIndent = 6;

/// The heading level (1–6) for a block type, or `null` if it isn't a heading.
int? headerLevel(Attribution? blockType) {
  if (blockType == header1Attribution) return 1;
  if (blockType == header2Attribution) return 2;
  if (blockType == header3Attribution) return 3;
  if (blockType == header4Attribution) return 4;
  if (blockType == header5Attribution) return 5;
  if (blockType == header6Attribution) return 6;
  return null;
}

/// The block type for a heading level (1–6).
Attribution headerAttribution(int level) => switch (level) {
  1 => header1Attribution,
  2 => header2Attribution,
  3 => header3Attribution,
  4 => header4Attribution,
  5 => header5Attribution,
  _ => header6Attribution,
};

bool isListLike(DocumentNode node) => node is ListItemNode || node is TaskNode;

/// A plain paragraph with no text, alignment or indent -- written as [emptyParagraphMarker], and dropped when trailing.
bool isEmptyParagraph(DocumentNode node) {
  if (node is! ParagraphNode || node.text.toPlainText().isNotEmpty || node.indent != 0) return false;

  final Attribution? blockType = node.getMetadataValue(NodeMetadata.blockType);
  if (blockType != null && blockType != paragraphAttribution) return false;

  final String? textAlign = node.getMetadataValue(TextNodeMetadata.textAlign);
  return textAlign == null || textAlign == 'left';
}
