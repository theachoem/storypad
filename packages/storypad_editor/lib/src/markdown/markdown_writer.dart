import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_registry.dart';
import 'inline_markdown_writer.dart';
import 'markdown_format.dart';

/// Writes a document as Markdown, in the canonical form [MarkdownReader] reads back exactly.
///
/// The format (see `markdown_format.dart` for the shared constants):
///
/// - Every block is **one line** (a hard line break inside text is an inline `<br>`), except a fenced code block and
///   an alignment/indent `<div>` wrapper.
/// - Blocks are separated by a blank line; consecutive list items and tasks by a single newline.
/// - An empty paragraph is a `&nbsp;` line. Trailing empty paragraphs are dropped.
/// - Nested list items and tasks are indented 4 spaces per level (correct nesting under both `-` and `1.` markers).
/// - A paragraph's (or heading's/quote's) non-left alignment and indent live on a wrapping
///   `<div style="text-align:…" data-indent="…">`, with blank lines inside so the content is still Markdown.
/// - Text that would read as block syntax at the start of a line (`#`, `-`, `+`, `1.`, …) is escaped.
class MarkdownWriter {
  MarkdownWriter(this.registry);

  final StoryEmbedRegistry registry;

  static const _inline = InlineMarkdownWriter();

  String write(Iterable<DocumentNode> nodes) {
    final blocks = nodes.toList();
    while (blocks.isNotEmpty && isEmptyParagraph(blocks.last)) {
      blocks.removeLast();
    }

    final buffer = StringBuffer();
    DocumentNode? previous;
    for (final node in blocks) {
      final markdown = writeNode(node);
      if (markdown == null) continue;

      if (previous != null) buffer.write(isListLike(previous) && isListLike(node) ? '\n' : '\n\n');
      buffer.write(markdown);
      previous = node;
    }
    return buffer.toString();
  }

  /// The Markdown for one block, or `null` for a node type the format can't represent.
  String? writeNode(DocumentNode node) {
    return switch (node) {
      ParagraphNode() => _paragraph(node),
      ListItemNode() => _listItem(node),
      TaskNode() => _task(node),
      HorizontalRuleNode() => '---',
      TextNode() => _escapedLine(node.text),
      _ => null,
    };
  }

  String _paragraph(ParagraphNode node) {
    final Attribution? blockType = node.getMetadataValue(NodeMetadata.blockType);
    if (blockType == codeAttribution) return _codeBlock(node.text.toPlainText());

    final level = headerLevel(blockType);
    final String content;
    if (level != null) {
      final text = _inline.write(node.text, escapeHash: true);
      content = text.isEmpty ? '#' * level : '${'#' * level} $text';
    } else if (blockType == blockquoteAttribution) {
      final text = _escapedLine(node.text);
      content = text.isEmpty ? '>' : '> $text';
    } else {
      content = node.text.toPlainText().isEmpty ? emptyParagraphMarker : _escapedLine(node.text);
    }

    final String? textAlign = node.getMetadataValue(TextNodeMetadata.textAlign);
    final align = textAlign == null || textAlign == 'left' ? null : textAlign;
    final indent = node.indent.clamp(0, maxIndent);
    if (align == null && indent == 0) return content;

    final attributes = [if (align != null) 'style="text-align:$align"', if (indent > 0) 'data-indent="$indent"'];
    return '<div ${attributes.join(' ')}>\n\n$content\n\n</div>';
  }

  String _listItem(ListItemNode node) {
    final marker = node.type == ListItemType.ordered ? '1.' : '-';
    final text = _escapedLine(node.text);
    return '${_indentation(node.indent)}$marker${text.isEmpty ? '' : ' $text'}';
  }

  String _task(TaskNode node) {
    final text = _escapedLine(node.text);
    return '${_indentation(node.indent)}- [${node.isComplete ? 'x' : ' '}]${text.isEmpty ? '' : ' $text'}';
  }

  static String _indentation(int indent) => ' ' * (listIndentWidth * indent.clamp(0, maxIndent));

  /// A fenced code block, with a fence longer than any backtick run in [code] so the content can't close it.
  static String _codeBlock(String code) {
    final longestRun = RegExp(
      '`+',
    ).allMatches(code).fold(0, (longest, m) => m[0]!.length > longest ? m[0]!.length : longest);
    final fence = '`' * (longestRun >= 3 ? longestRun + 1 : 3);
    return '$fence\n$code\n$fence';
  }

  /// [text] as inline Markdown, escaped so it can't be read as block syntax at the start of a line.
  static String _escapedLine(AttributedText text) => escapeLineStart(_inline.write(text));
}

/// Escapes inline Markdown that would otherwise be read as block syntax at the start of a line: `#` (heading), `-`/`+`
/// (list item, rule), `1.`/`1)` (ordered list item). The inline writer already escapes everything else that matters
/// (`*`, `_`, `` ` ``, `~`, `[`, `<`, `>`).
///
/// A whitespace-only line would read as blank, so its whitespace is written as character references.
String escapeLineStart(String markdown) {
  if (markdown.isEmpty) return markdown;
  if (markdown.trim().isEmpty) return markdown.codeUnits.map((unit) => '&#$unit;').join();

  final match = _lineStartSyntax.firstMatch(markdown);
  if (match == null) return markdown;

  final leading = match[1]!;
  final ordered = match[2];
  if (ordered != null) {
    // "1." → "1\.", so it isn't an ordered list marker.
    final punctuation = ordered[ordered.length - 1];
    return '$leading${ordered.substring(0, ordered.length - 1)}\\$punctuation${markdown.substring(match.end)}';
  }
  return '$leading\\${markdown.substring(leading.length)}';
}

final _lineStartSyntax = RegExp(r'^([ \t]*)(?:(\d{1,9}[.)])|[#+=-])');
