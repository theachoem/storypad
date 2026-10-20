import 'dart:convert';

import 'package:super_editor/super_editor.dart';

import '../embed/quill_embed_op.dart';
import '../embed/story_embed_node.dart';
import '../embed/story_embed_registry.dart';
import '../embed/story_html_element.dart';
import '../embed/unknown_embed_value.dart';
import 'inline_markdown_reader.dart';
import 'markdown_format.dart';
import 'markdown_block.dart';
import 'markdown_image_line.dart';
import '../document/heading.dart';

/// Reads Markdown into document nodes.
///
/// Reads [MarkdownWriter]'s canonical format exactly, and ordinary hand-written Markdown reasonably: ATX headings,
/// fenced code (`` ``` `` and `~~~`), block quotes, bullet/ordered/task lists (any consistent 2-, 3- or 4-space
/// nesting), thematic breaks, and paragraphs whose lines are joined with line breaks (so text pasted from a notes app
/// keeps its lines).
///
/// This is a small line-based block parser rather than super_editor's `deserializeMarkdownToDocument`, whose block
/// handling loses information this storage format can't afford to lose (task indent, nested tasks, blank-line and
/// hard-break ambiguity). Inline content still goes through `package:markdown`'s CommonMark inline parser (see
/// [InlineMarkdownReader]).
///
/// Embeds: a line holding exactly one HTML element whose tag an embed claims is read through that embed's `fromHtml`;
/// a bare `![alt](src)` line through the embed claiming `img` (or a stock `ImageNode` if none does). A line an embed
/// rejects, and any `<sp-…>` line no embed claims (e.g. from a newer app version), is kept verbatim by the unknown
/// embed -- never dropped.
///
/// Never throws on malformed input; anything unrecognized becomes paragraph text.
class MarkdownReader {
  MarkdownReader(this.registry);

  final StoryEmbedRegistry registry;

  static const _inline = InlineMarkdownReader();

  /// Reads [markdown]. Always returns at least one node (an empty paragraph for empty input), so an editor always has
  /// somewhere to put the caret.
  List<DocumentNode> read(String markdown) {
    final nodes = readLines(const LineSplitter().convert(markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n')));
    return nodes.isEmpty ? [ParagraphNode(id: Editor.createNodeId(), text: AttributedText())] : nodes;
  }

  /// Reads a sequence of lines (also used for the content of an alignment `<div>`).
  List<DocumentNode> readLines(List<String> lines) {
    final nodes = <DocumentNode>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().isEmpty && !_isBlankLineMarker(line)) {
        i++;
        continue;
      }

      final block = readBlock(lines, i);
      if (block != null) {
        nodes.addAll(block.nodes);
        i = block.end;
        continue;
      }

      final paragraph = _paragraph(lines, i);
      nodes.add(paragraph.nodes.single);
      i = paragraph.end;
    }
    return nodes;
  }

  /// Reads the non-paragraph block starting at [lines][start], or returns `null` if a paragraph starts there.
  MarkdownBlock? readBlock(List<String> lines, int start) {
    final line = lines[start];
    return _fencedCode(lines, start) ??
        (_isBlankLineMarker(line) ? MarkdownBlock([_emptyParagraph()], start + 1) : null) ??
        _wrapper(lines, start) ??
        _embed(lines, start) ??
        _image(lines, start) ??
        (_thematicBreak.hasMatch(line)
            ? MarkdownBlock([HorizontalRuleNode(id: Editor.createNodeId())], start + 1)
            : null) ??
        _heading(lines, start) ??
        _listItem(lines, start) ??
        _blockquote(lines, start);
  }

  static final _fenceOpen = RegExp(r'^( {0,3})(`{3,}|~{3,})(.*)$', dotAll: true);
  static final _thematicBreak = RegExp(r'^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$');
  static final _headingLine = RegExp(r'^ {0,3}(#{1,6})(?:[ \t](.*))?$', dotAll: true);
  static final _closingHashes = RegExp(r'(?:^|[ \t]+)#+[ \t]*$');
  static final _listLine = RegExp(r'^( *)([-*+]|\d{1,9}[.)])(?:[ \t](.*))?$', dotAll: true);
  static final _taskContent = RegExp(r'^\[([ xX])\](?:[ \t](.*))?$', dotAll: true);
  static final _quoteLine = RegExp(r'^ {0,3}>[ \t]?(.*)$', dotAll: true);
  static final _divOpen = RegExp(r'^<div(?:\s[^>]*)?>\s*$', caseSensitive: false);

  MarkdownBlock? _fencedCode(List<String> lines, int start) {
    final match = _fenceOpen.firstMatch(lines[start]);
    if (match == null) return null;

    final indent = match[1]!.length;
    final fence = match[2]!;
    // A backtick fence's info string can't contain backticks (then it's inline code instead).
    if (fence.startsWith('`') && match[3]!.contains('`')) return null;

    final closing = RegExp('^ {0,3}${RegExp.escape(fence[0])}{${fence.length},}[ \\t]*\$');
    final content = <String>[];
    var i = start + 1;
    while (i < lines.length && !closing.hasMatch(lines[i])) {
      final line = lines[i];
      final strip = RegExp('^ {0,$indent}').firstMatch(line)![0]!.length;
      content.add(line.substring(strip));
      i++;
    }

    final node = ParagraphNode(
      id: Editor.createNodeId(),
      text: AttributedText(content.join('\n')),
      metadata: const {NodeMetadata.blockType: codeAttribution},
    );
    // An unclosed fence runs to the end of the document, like CommonMark.
    return MarkdownBlock([node], i < lines.length ? i + 1 : i);
  }

  /// An alignment/indent `<div>` wrapper. Its content is read recursively, and the wrapper's alignment and indent are
  /// applied to the (non-code) paragraphs, headings and quotes inside; its alignment also to list items and tasks
  /// (whose indent is their nesting). Without a closing `</div>` line it isn't a
  /// wrapper, and the line is read as paragraph text instead of swallowing the rest of the document.
  MarkdownBlock? _wrapper(List<String> lines, int start) {
    if (!_divOpen.hasMatch(lines[start])) return null;

    final end = lines.indexWhere((line) => line.trim().toLowerCase() == '</div>', start + 1);
    if (end == -1) return null;

    final element = StoryHtmlElement.tryParse(lines[start]);
    final style = element?['style'] ?? '';
    final align = RegExp(r'text-align\s*:\s*(left|center|right|justify)').firstMatch(style)?[1];
    final indent = (int.tryParse(element?['data-indent'] ?? '') ?? 0).clamp(0, MarkdownFormat.maxIndent);

    final inner = readLines(lines.sublist(start + 1, end));
    final nodes = [
      for (final node in inner)
        if (node is ParagraphNode && node.getMetadataValue(NodeMetadata.blockType) != codeAttribution)
          node.copyParagraphWith(
            indent: indent,
            metadata: {...node.metadata, if (align != null && align != 'left') TextNodeMetadata.textAlign: align},
          )
        else if (MarkdownFormat.isListLike(node) && align != null && align != 'left')
          node.copyWithAddedMetadata({TextNodeMetadata.textAlign: align})
        else
          node,
    ];
    return MarkdownBlock(nodes, end + 1);
  }

  static final _htmlLine = RegExp(r'^ {0,3}<([a-zA-Z][a-zA-Z0-9-]*)');

  MarkdownBlock? _embed(List<String> lines, int start) {
    final match = _htmlLine.firstMatch(lines[start]);
    if (match == null) return null;

    final tag = match[1]!.toLowerCase();
    if (StoryEmbedRegistry.reservedTags.contains(tag)) return null;
    final embed = registry.byHtmlTag(tag);

    final line = lines[start].trim();
    final element = StoryHtmlElement.tryParseSingle(line);
    // "<img …> caption" is text, not an embed line -- except that an unclaimed <sp-…> line is always kept.
    if (element == null && (embed != null || !tag.startsWith('sp-'))) return null;

    // An element no embed claims (e.g. a newer app's embed, or one this app doesn't register) is kept verbatim.
    final node = (element != null && element.tag == tag ? embed?.nodeFromHtml(element) : null) ?? _unknownLine(line);
    return MarkdownBlock([_upgradeUnknown(node)], start + 1);
  }

  MarkdownBlock? _image(List<String> lines, int start) {
    final line = lines[start];
    if (!line.trimLeft().startsWith('![')) return null;

    final image = MarkdownImageLine.read(line);
    if (image == null) return null;

    final embed = registry.byHtmlTag('img');
    final DocumentNode node;
    if (embed == null) {
      node = ImageNode(id: Editor.createNodeId(), imageUrl: image.src, altText: image.alt);
    } else {
      final element = StoryHtmlElement(
        'img',
        attributes: {'src': image.src, if (image.alt.isNotEmpty) 'alt': image.alt},
      );
      node = embed.nodeFromHtml(element) ?? _unknownLine(line.trim());
    }
    return MarkdownBlock([node], start + 1);
  }

  DocumentNode _unknownLine(String line) => registry.unknown.createNode(UnknownHtmlEmbed(line));

  /// A Quill op the unknown embed kept (e.g. saved by an app version without that embed) goes to the embed importing
  /// its key, if one is registered now.
  DocumentNode _upgradeUnknown(DocumentNode node) {
    if (node is! StoryEmbedNode || node.type != registry.unknown.type) return node;
    final value = node.value;
    if (value is! UnknownQuillEmbed) return node;
    final insert = value.op['insert'];
    final key = value.key;
    final embed = key == null ? null : registry.byQuillKey(key);
    if (embed == null || insert is! Map) return node;

    final attributes = value.op['attributes'];
    final op = QuillEmbedOp(
      key: key!,
      insert: Map<String, Object?>.from(insert),
      attributes: attributes is Map ? Map<String, Object?>.from(attributes) : const {},
    );
    return embed.nodeFromQuill(op, id: node.id) ?? node;
  }

  MarkdownBlock? _heading(List<String> lines, int start) {
    final match = _headingLine.firstMatch(lines[start]);
    if (match == null) return null;

    final level = match[1]!.length;
    // The writer escapes every '#' in heading text, so only hand-written headings have a closing sequence.
    final content = (match[2] ?? '').replaceFirst(_closingHashes, '');
    final node = ParagraphNode(
      id: Editor.createNodeId(),
      text: _inline.read(content),
      metadata: {NodeMetadata.blockType: Heading.blockType(level)},
    );
    return MarkdownBlock([node], start + 1);
  }

  MarkdownBlock? _listItem(List<String> lines, int start) {
    final match = _listLine.firstMatch(lines[start]);
    if (match == null) return null;

    final leading = match[1]!.length;
    final marker = match[2]!;
    var content = match[3] ?? '';
    final contentColumn = leading + marker.length + 1;

    // Continuation lines: indented at least to the content column, and not list items themselves.
    var end = start + 1;
    while (end < lines.length) {
      final line = lines[end];
      if (line.trim().isEmpty || _listLine.hasMatch(line)) break;
      if (!line.startsWith(' ' * contentColumn)) break;
      content += '\n${line.substring(contentColumn)}';
      end++;
    }

    // 4 spaces per level is canonical; (leading + 2) ~/ 4 also reads 2- and 3-space nesting sensibly.
    final indent = ((leading + 2) ~/ MarkdownFormat.listIndentWidth).clamp(0, MarkdownFormat.maxIndent);
    final isBullet = marker.length == 1 && !RegExp(r'\d').hasMatch(marker);

    final task = isBullet ? _taskContent.firstMatch(content) : null;
    if (task != null) {
      final node = TaskNode(
        id: Editor.createNodeId(),
        text: _inline.read(task[2] ?? ''),
        isComplete: task[1] != ' ',
        indent: indent,
      );
      return MarkdownBlock([node], end);
    }

    final node = ListItemNode(
      id: Editor.createNodeId(),
      itemType: isBullet ? ListItemType.unordered : ListItemType.ordered,
      text: _inline.read(content),
      indent: indent,
    );
    return MarkdownBlock([node], end);
  }

  MarkdownBlock? _blockquote(List<String> lines, int start) {
    final contents = <String>[];
    var end = start;
    while (end < lines.length) {
      final match = _quoteLine.firstMatch(lines[end]);
      if (match == null) break;
      contents.add(match[1]!);
      end++;
    }
    if (contents.isEmpty) return null;

    final node = ParagraphNode(
      id: Editor.createNodeId(),
      text: _inline.read(contents.join('\n')),
      metadata: const {NodeMetadata.blockType: blockquoteAttribution},
    );
    return MarkdownBlock([node], end);
  }

  /// A paragraph: this line plus following lines up to a blank line or the start of another block, joined with line
  /// breaks.
  MarkdownBlock _paragraph(List<String> lines, int start) {
    final content = [lines[start]];
    var end = start + 1;
    while (end < lines.length && lines[end].trim().isNotEmpty && readBlock(lines, end) == null) {
      content.add(lines[end]);
      end++;
    }
    return MarkdownBlock([ParagraphNode(id: Editor.createNodeId(), text: _inline.read(content.join('\n')))], end);
  }

  static ParagraphNode _emptyParagraph() => ParagraphNode(id: Editor.createNodeId(), text: AttributedText());

  /// A line holding a blank line: the writer's [MarkdownFormat.emptyParagraphMarker] -- or that marker already decoded
  /// into its character (a lone non-breaking space), as stored content went through an HTML-entity decode in earlier
  /// StoryPad versions. The writer never writes a bare non-breaking space (whitespace-only text becomes character
  /// references).
  static bool _isBlankLineMarker(String line) {
    final trimmed = line.trim();
    if (trimmed == MarkdownFormat.emptyParagraphMarker) return true;
    return trimmed.isEmpty && line.contains('\u00a0');
  }
}
