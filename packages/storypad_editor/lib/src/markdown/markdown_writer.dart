import 'package:markdown/markdown.dart' as md;
import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';
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
/// - An empty paragraph is a `&nbsp;` line -- wherever it is, first and last included: blank lines are the writer's own.
///   Only a document that is nothing but one empty paragraph (a blank page) is written as nothing.
/// - Nested list items and tasks are indented 4 spaces per level (correct nesting under both `-` and `1.` markers).
/// - A paragraph's (or heading's/quote's) non-left alignment and indent live on a wrapping
///   `<div style="text-align:…" data-indent="…">`, with blank lines inside so the content is still Markdown. A run of
///   consecutive list items/tasks sharing an alignment is wrapped as a whole (their indent is their nesting).
/// - Text that would read as block syntax at the start of a line (`#`, `-`, `+`, `1.`, …) is escaped.
/// - An embed is one line of HTML from its codec's `toHtml` -- except an `<img>` with only `src`/`alt`, which is
///   written as Markdown's own `![alt](src)` when that reads back identically.
class MarkdownWriter {
  MarkdownWriter(this.registry);

  final StoryEmbedRegistry registry;

  static const _inline = InlineMarkdownWriter();

  String write(Iterable<DocumentNode> nodes) {
    final blocks = nodes.toList();
    if (blocks.length == 1 && isEmptyParagraph(blocks.single)) return '';

    final buffer = StringBuffer();
    DocumentNode? previous;
    var previousWrapped = false;
    for (var i = 0; i < blocks.length; i++) {
      final node = blocks[i];

      // A run of list items/tasks sharing a (non-left) alignment is one wrapper.
      final align = isListLike(node) ? _alignment(node) : null;
      if (align != null) {
        final items = <String>[];
        for (; i < blocks.length && isListLike(blocks[i]) && _alignment(blocks[i]) == align; i++) {
          items.add(writeNode(blocks[i])!);
        }
        i--;
        if (previous != null) buffer.write('\n\n');
        buffer.write('<div style="text-align:$align">\n\n${items.join('\n')}\n\n</div>');
        previous = blocks[i];
        previousWrapped = true;
        continue;
      }

      final markdown = writeNode(node);
      if (markdown == null) continue;

      if (previous != null) {
        buffer.write(!previousWrapped && isListLike(previous) && isListLike(node) ? '\n' : '\n\n');
      }
      buffer.write(markdown);
      previous = node;
      previousWrapped = false;
    }
    return buffer.toString();
  }

  /// [node]'s alignment, or `null` for left (the default).
  static String? _alignment(DocumentNode node) {
    final String? textAlign = node.getMetadataValue(TextNodeMetadata.textAlign);
    return textAlign == null || textAlign == 'left' ? null : textAlign;
  }

  /// The Markdown for one block, or `null` for a node type the format can't represent.
  String? writeNode(DocumentNode node) {
    return switch (node) {
      StoryEmbedNode() => _embed(node),
      ImageNode() =>
        _markdownImage(node.imageUrl, node.altText) ?? _canonicalMarkdownImage(node.imageUrl, node.altText),
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
    // Line endings in code are normalized: a lone \r would read back as a line break anyway.
    if (blockType == codeAttribution) {
      return _codeBlock(node.text.toPlainText().replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
    }

    final level = headerLevel(blockType);
    final String content;
    if (level != null) {
      final text = protectTrailingWhitespace(_inline.write(node.text, escapeHash: true));
      content = text.isEmpty ? '#' * level : '${'#' * level} $text';
    } else if (blockType == blockquoteAttribution) {
      final text = _escapedLine(node.text);
      content = text.isEmpty ? '>' : '> $text';
    } else {
      content = node.text.toPlainText().isEmpty ? emptyParagraphMarker : _escapedLine(node.text);
    }

    final align = _alignment(node);
    final indent = node.indent.clamp(0, maxIndent);
    if (align == null && indent == 0) return content;

    final attributes = [if (align != null) 'style="text-align:$align"', if (indent > 0) 'data-indent="$indent"'];
    return '<div ${attributes.join(' ')}>\n\n$content\n\n</div>';
  }

  String _embed(StoryEmbedNode node) {
    final embed = registry.forNode(node);
    if (embed == null) {
      throw StateError(
        'No embed registered for "${node.type}" (node ${node.id}). Encode with the same embeds the document was '
        'created with.',
      );
    }

    final element = embed.toHtmlOf(node);
    if (!element.isRaw && element.tag == 'img' && element.children.isEmpty) {
      final keys = element.attributes.keys.toSet();
      final src = element['src'];
      if (src != null && keys.difference({'src', 'alt'}).isEmpty) {
        final image = _markdownImage(src, element['alt'] ?? '');
        if (image != null) return image;
      }
    }
    return element.render();
  }

  /// `![alt](src)` with [src] as Markdown normalizes it (e.g. spaces percent-encoded), so writing it again is a fixed
  /// point.
  static String _canonicalMarkdownImage(String src, String alt) {
    final canonical = readMarkdownImage('![](${linkDestination(src)})')?.src ?? src;
    return '![${escapeText(alt)}](${linkDestination(canonical)})';
  }

  /// `![alt](src)`, if it reads back as exactly [src] and [alt] (Markdown normalizes some destinations, e.g. by
  /// percent-encoding spaces, and parses the alt text as inline Markdown); otherwise `null`.
  static String? _markdownImage(String src, String alt) {
    final markdown = '![${escapeText(alt)}](${linkDestination(src)})';
    final parsed = readMarkdownImage(markdown);
    return parsed != null && parsed.src == src && parsed.alt == alt ? markdown : null;
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
/// A whitespace-only line would read as blank, so its whitespace is written as character references (as is trailing
/// whitespace, see [protectTrailingWhitespace]).
String escapeLineStart(String markdown) {
  if (markdown.isEmpty) return markdown;
  if (markdown.trim().isEmpty) return markdown.codeUnits.map((unit) => '&#$unit;').join();
  markdown = protectTrailingWhitespace(markdown);

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

/// Writes trailing spaces/tabs as character references: they're content, but editors and tools routinely trim them.
/// A whitespace-only line is all trailing whitespace.
String protectTrailingWhitespace(String markdown) {
  final match = _trailingWhitespace.firstMatch(markdown);
  if (match == null) return markdown;
  // package:markdown doesn't decode a reference right after a backtick (a code span's end): separate them.
  final separator = match.start > 0 && markdown[match.start - 1] == '`' ? '<wbr>' : '';
  return markdown.substring(0, match.start) + separator + match[0]!.codeUnits.map((unit) => '&#$unit;').join();
}

final _trailingWhitespace = RegExp(r'[ \t]+$');

final _lineStartSyntax = RegExp(r'^([ \t]*)(?:(\d{1,9}[.)])|[#+=-])');

/// Reads a line consisting of exactly one Markdown image, `![alt](src)`, or returns `null`.
({String src, String alt})? readMarkdownImage(String line) {
  final nodes = md.InlineParser(line.trim(), md.Document(encodeHtml: false)).parse();
  if (nodes.length != 1) return null;

  final node = nodes.single;
  if (node is! md.Element || node.tag != 'img') return null;
  return (src: node.attributes['src'] ?? '', alt: node.attributes['alt'] ?? '');
}
