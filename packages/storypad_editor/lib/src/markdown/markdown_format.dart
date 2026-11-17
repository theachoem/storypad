import 'package:super_editor/super_editor.dart';

/// What the Markdown writer and reader share, and must agree on exactly.
class MarkdownFormat {
  const MarkdownFormat._();

  /// The line written for an empty paragraph. Also how many Markdown users write an intentional blank line.
  static const emptyParagraphMarker = '&nbsp;';

  /// Spaces per list/task nesting level.
  static const listIndentWidth = 4;

  /// The deepest indent the format writes or reads, for lists, tasks and paragraphs. Also bounds how much work a
  /// malformed document (e.g. a huge indent) can cause.
  static const maxIndent = 6;

  static bool isListLike(DocumentNode node) => node is ListItemNode || node is TaskNode;

  /// What goes between two written blocks: a single newline between list items/tasks, so they stay one list; a blank
  /// line otherwise. [gap]: something between them was left out of the output (an empty line, an embed), so a blank
  /// line keeps them apart -- else two tasks an empty line apart would come out as one list.
  ///
  /// The one rule every Markdown writer follows: the storage writer, and the readable ones for export and sharing.
  static String blockSeparator({required bool previousIsListItem, required bool nextIsListItem, bool gap = false}) {
    return previousIsListItem && nextIsListItem && !gap ? '\n' : '\n\n';
  }

  /// A plain paragraph with no text, alignment or indent -- written as [emptyParagraphMarker].
  static bool isEmptyParagraph(DocumentNode node) {
    if (node is! ParagraphNode || node.text.toPlainText().isNotEmpty || node.indent != 0) return false;

    final Attribution? blockType = node.getMetadataValue(NodeMetadata.blockType);
    if (blockType != null && blockType != paragraphAttribution) return false;

    final String? textAlign = node.getMetadataValue(TextNodeMetadata.textAlign);
    return textAlign == null || textAlign == 'left';
  }
}
