import 'dart:convert';

import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_registry.dart';
import '../embed/story_html_element.dart';
import 'inline_markdown_reader.dart';
import 'markdown_format.dart';

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
/// Never throws on malformed input; anything unrecognized becomes paragraph text.
class MarkdownReader {
  MarkdownReader(this.registry);

  final StoryEmbedRegistry registry;

  static const _inline = InlineMarkdownReader();

  /// Reads [markdown]. Always returns at least one node (an empty paragraph for empty input), so an editor always has
  /// somewhere to put the caret.
  List<DocumentNode> read(String markdown) {
    final nodes = readLines(const LineSplitter().convert(markdown));
    return nodes.isEmpty ? [ParagraphNode(id: Editor.createNodeId(), text: AttributedText())] : nodes;
  }

  /// Reads a sequence of lines (also used for the content of an alignment `<div>`).
  List<DocumentNode> readLines(List<String> lines) {
    final nodes = <DocumentNode>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().isEmpty) {
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
        (line.trim() == emptyParagraphMarker ? MarkdownBlock([_emptyParagraph()], start + 1) : null) ??
        _wrapper(lines, start) ??
        (_thematicBreak.hasMatch(line)
            ? MarkdownBlock([HorizontalRuleNode(id: Editor.createNodeId())], start + 1)
            : null) ??
        _heading(lines, start) ??
        _listItem(lines, start) ??
        _blockquote(lines, start);
  }

  static final _fenceOpen = RegExp(r'^( {0,3})(`{3,}|~{3,})(.*)$');
  static final _thematicBreak = RegExp(r'^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$');
  static final _headingLine = RegExp(r'^ {0,3}(#{1,6})(?:[ \t](.*))?$');
  static final _closingHashes = RegExp(r'(?:^|[ \t]+)#+[ \t]*$');
  static final _listLine = RegExp(r'^( *)([-*+]|\d{1,9}[.)])(?:[ \t](.*))?$');
  static final _taskContent = RegExp(r'^\[([ xX])\](?:[ \t](.*))?$');
  static final _quoteLine = RegExp(r'^ {0,3}>[ \t]?(.*)$');
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
  /// applied to the (non-code) paragraphs, headings and quotes inside. Without a closing `</div>` line it isn't a
  /// wrapper, and the line is read as paragraph text instead of swallowing the rest of the document.
  MarkdownBlock? _wrapper(List<String> lines, int start) {
    if (!_divOpen.hasMatch(lines[start])) return null;

    final end = lines.indexWhere((line) => line.trim().toLowerCase() == '</div>', start + 1);
    if (end == -1) return null;

    final element = StoryHtmlElement.tryParse(lines[start]);
    final style = element?['style'] ?? '';
    final align = RegExp(r'text-align\s*:\s*(left|center|right|justify)').firstMatch(style)?[1];
    final indent = (int.tryParse(element?['data-indent'] ?? '') ?? 0).clamp(0, maxIndent);

    final inner = readLines(lines.sublist(start + 1, end));
    final nodes = [
      for (final node in inner)
        if (node is ParagraphNode && node.getMetadataValue(NodeMetadata.blockType) != codeAttribution)
          node.copyParagraphWith(
            indent: indent,
            metadata: {...node.metadata, if (align != null && align != 'left') TextNodeMetadata.textAlign: align},
          )
        else
          node,
    ];
    return MarkdownBlock(nodes, end + 1);
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
      metadata: {NodeMetadata.blockType: headerAttribution(level)},
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
    final indent = ((leading + 2) ~/ listIndentWidth).clamp(0, maxIndent);
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
}

/// Nodes read from `lines[start, end)`.
class MarkdownBlock {
  MarkdownBlock(this.nodes, this.end);

  final List<DocumentNode> nodes;

  /// The index of the first line after the block.
  final int end;
}
