import 'dart:ui';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/types/time_format_option.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// A story as text to share: a header (date, tags, feelings), then each page's blocks, one line per block, as plain
/// text or as Markdown ([markdown]).
///
/// It reads the pages' documents as they are (e.g. the editors' `editor.document`), not the stored Markdown: stored
/// Markdown is written for reading back exactly (`&nbsp;` for empty lines, HTML for alignment and colors), which isn't
/// something to paste into a message. Photos, voice notes and other embeds are left out -- they're shared as files.
class StoryPlainTextExporter {
  final DateTime displayPathDate;
  final List<Iterable<DocumentNode>> pages;
  final Locale locale;
  final TimeFormatOption timeFormat;
  final List<TagDbModel> tags;
  final List<String> emojis;
  final bool markdown;

  StoryPlainTextExporter({
    required this.displayPathDate,
    required this.pages,
    required this.tags,
    required this.emojis,
    required this.timeFormat,
    required this.locale,
    required this.markdown,
  });

  String export() {
    final header = [
      timeFormat.formatDateTime(displayPathDate, locale),
      if (tags.isNotEmpty) tags.map((t) => t.title).join(', '),
      if (emojis.isNotEmpty) emojis.join(' '),
    ].join('\n');

    final pagesText = pages.map(_page).where((text) => text.isNotEmpty).join('\n\n---\n\n');
    return "$header\n\n$pagesText\n\n#StoryPad";
  }

  /// A page, title (its leading heading) included.
  String _page(Iterable<DocumentNode> nodes) {
    final blocks = <_Block>[];
    final orderedCounts = <int, int>{};

    for (final node in nodes) {
      // An embed leaves an empty line, so the text around it stays apart -- one, however many embeds in a row.
      if (node is StoryEmbedNode || node is ImageNode) {
        if (blocks.isNotEmpty && blocks.last.text.isNotEmpty) blocks.add(const _Block('', listItem: false));
        continue;
      }

      // An ordered list numbers each level on from its previous item; anything else ends the list at its level.
      final level = switch (node) {
        ListItemNode() => node.indent,
        TaskNode() => node.indent,
        _ => -1,
      };
      final ordered = node is ListItemNode && node.type == ListItemType.ordered;
      orderedCounts.removeWhere((l, _) => l > level || (l == level && !ordered));

      final line = _block(node, orderedCounts);
      if (line != null) blocks.add(_Block(line, listItem: node is ListItemNode || node is TaskNode));
    }

    return _join(blocks).trim();
  }

  /// Plain text: one line per block. Markdown: a blank line between blocks -- on one newline, two paragraphs read as
  /// one, and text right above `---` as a heading -- except between list items, which stay one list. Empty blocks
  /// (empty lines, embeds) are dropped there: the blank line already keeps their neighbors apart.
  String _join(List<_Block> blocks) {
    if (!markdown) return blocks.map((block) => block.text).join('\n');

    final buffer = StringBuffer();
    _Block? previous;
    for (final block in blocks) {
      if (block.text.isEmpty) continue;
      if (previous != null) buffer.write(previous.listItem && block.listItem ? '\n' : '\n\n');
      buffer.write(block.text);
      previous = block;
    }
    return buffer.toString();
  }

  /// One block as a line (a code block as several), or `null` for a block that has no text form.
  String? _block(DocumentNode node, Map<int, int> orderedCounts) {
    return switch (node) {
      ListItemNode() => '${_indent(node.indent)}${_listMarker(node, orderedCounts)} ${_inline(node.text)}',
      TaskNode() => '${_indent(node.indent)}${_taskMarker(node.isComplete)} ${_inline(node.text)}',
      ParagraphNode() => _paragraph(node),
      HorizontalRuleNode() => '---',
      TextNode() => _inline(node.text),
      _ => null,
    };
  }

  String _paragraph(ParagraphNode node) {
    final Attribution? blockType = node.getMetadataValue(NodeMetadata.blockType);
    final text = node.text.toPlainText();

    if (blockType == codeAttribution) return markdown ? '```\n$text\n```' : text;
    if (blockType == blockquoteAttribution) return '${'> ' * (node.indent + 1)}${_inline(node.text)}';

    final level = _headingLevel(blockType);
    if (markdown && level != null && text.isNotEmpty) return '${'#' * level} ${_inline(node.text)}';

    return '${_indent(node.indent)}${_inline(node.text)}';
  }

  static int? _headingLevel(Attribution? blockType) {
    if (blockType is! NamedAttribution || !blockType.id.startsWith('header')) return null;
    return int.tryParse(blockType.id.substring('header'.length));
  }

  static String _indent(int indent) => '\t' * indent;

  /// `-`, or the item's number: `1.` at the top level; in plain text `a.` one level in and `i.` two levels in.
  String _listMarker(ListItemNode node, Map<int, int> orderedCounts) {
    if (node.type != ListItemType.ordered) return '-';

    final index = orderedCounts[node.indent] = (orderedCounts[node.indent] ?? 0) + 1;
    if (markdown) return '$index.';
    return switch (node.indent) {
      1 when index <= 26 => '${String.fromCharCode(96 + index)}.',
      2 => '${_roman(index)}.',
      _ => '$index.',
    };
  }

  String _taskMarker(bool done) {
    if (markdown) return done ? '- [x]' : '- [ ]';
    return done ? '✅' : '⏹️';
  }

  /// [text] with its bold, italics, strikethrough, inline code and links as Markdown; plain text as is.
  String _inline(AttributedText text) {
    final plainText = text.toPlainText();
    if (!markdown) return plainText;

    final buffer = StringBuffer();
    var start = 0;
    while (start < plainText.length) {
      final style = _InlineStyle.at(text, start);
      var end = start + 1;
      while (end < plainText.length && _InlineStyle.at(text, end) == style) {
        end++;
      }
      buffer.write(style.wrap(plainText.substring(start, end)));
      start = end;
    }
    return buffer.toString();
  }

  static String _roman(int number) {
    const numerals = {
      1000: 'm',
      900: 'cm',
      500: 'd',
      400: 'cd',
      100: 'c',
      90: 'xc',
      50: 'l',
      40: 'xl',
      10: 'x',
      9: 'ix',
      5: 'v',
      4: 'iv',
      1: 'i',
    };

    final buffer = StringBuffer();
    var n = number;
    for (final MapEntry(key: value, value: symbol) in numerals.entries) {
      for (; n >= value; n -= value) {
        buffer.write(symbol);
      }
    }
    return buffer.toString();
  }
}

/// A block's text, and whether it's a list (or task) item.
class _Block {
  const _Block(this.text, {required this.listItem});

  final String text;
  final bool listItem;
}

/// The inline formatting a run of text is shared with.
class _InlineStyle {
  const _InlineStyle({
    required this.bold,
    required this.italic,
    required this.strikethrough,
    required this.code,
    required this.link,
  });

  factory _InlineStyle.at(AttributedText text, int offset) {
    final attributions = text.getAllAttributionsAt(offset);
    return _InlineStyle(
      bold: attributions.contains(boldAttribution),
      italic: attributions.contains(italicsAttribution),
      strikethrough: attributions.contains(strikethroughAttribution),
      code: attributions.contains(codeAttribution),
      link: attributions.whereType<LinkAttribution>().firstOrNull?.plainTextUri,
    );
  }

  final bool bold;
  final bool italic;
  final bool strikethrough;
  final bool code;
  final String? link;

  /// [text] in this style's Markdown, a link around its other styles (`[**a**](url)`).
  String wrap(String text) {
    final styled = _styled(text);
    return link != null ? '[$styled]($link)' : styled;
  }

  /// Spaces at either end stay outside the delimiters: `** a**` isn't bold.
  String _styled(String text) {
    final core = text.trim();
    if (core.isEmpty) return text;

    var styled = core;
    if (code) styled = '`$styled`';
    if (strikethrough) styled = '~~$styled~~';
    if (italic) styled = '*$styled*';
    if (bold) styled = '**$styled**';

    final leading = text.substring(0, text.indexOf(core));
    final trailing = text.substring(leading.length + core.length);
    return '$leading$styled$trailing';
  }

  @override
  bool operator ==(Object other) {
    return other is _InlineStyle &&
        other.bold == bold &&
        other.italic == italic &&
        other.strikethrough == strikethrough &&
        other.code == code &&
        other.link == link;
  }

  @override
  int get hashCode => Object.hash(bold, italic, strikethrough, code, link);
}
