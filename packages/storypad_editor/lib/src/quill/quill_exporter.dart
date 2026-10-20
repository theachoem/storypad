import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';
import '../embed/story_embed_registry.dart';
import '../markdown/markdown_format.dart';
import '../markdown/markdown_writer.dart';
import '../document/heading.dart';
import 'quill_color.dart';

/// Writes document nodes as Quill Delta ops, in the shapes StoryPad's Quill editor wrote, for readers built on Quill
/// and for `StoryCodec.checkQuillPage`'s round trip. The mirror of `QuillImporter`: importing the result gives an
/// equivalent document.
///
/// - **Blocks** (on each line's `\n`): `header`, `list` (`bullet`/`ordered`/`checked`/`unchecked`), `blockquote`,
///   `code-block` (`true`), `align` (unless left), `indent`. A node holding line breaks (a multi-line quote or code
///   block, or a soft line break) becomes one Quill line per line, each with the node's block attributes.
/// - **Inline**: `bold`, `italic`, `underline`, `strike`, `code`, `script`, `link`, and `color`/`background` as
///   lowercase `#aarrggbb` (alpha first). Code blocks hold plain text.
/// - **Embeds**: the embed's `toQuill` op on its own line. An embed without a Quill form (or a node Quill can't
///   express) is written as one line of this package's Markdown under the `sp-markdown` key, which imports back
///   exactly. A horizontal rule is `{"divider": "hr"}`.
///
/// Ops are normalized the way Quill does (adjacent inserts with equal attributes merge), and the result always ends
/// with `\n`.
class QuillExporter {
  QuillExporter(this.registry, this.markdown);

  final StoryEmbedRegistry registry;
  final MarkdownWriter markdown;

  static const dividerKey = 'divider';

  static const markdownKey = 'sp-markdown';

  List<Map<String, Object?>> export(Iterable<DocumentNode> nodes) {
    // Blank lines are kept, trailing ones included (as in Markdown): each is its own "\n".
    final delta = Delta();
    for (final node in nodes) {
      _writeNode(delta, node);
    }
    if (delta.isEmpty) delta.insert('\n');
    return [for (final operation in delta.toList()) Map<String, Object?>.from(operation.toJson())];
  }

  void _writeNode(Delta delta, DocumentNode node) {
    switch (node) {
      case StoryEmbedNode():
        final op = registry.forNode(node)?.toQuillOf(node);
        if (op != null) {
          delta.insert(op.insert, op.attributes.isEmpty ? null : op.attributes);
          delta.insert('\n');
        } else {
          _writeMarkdownLine(delta, node);
        }
      case HorizontalRuleNode():
        delta.insert({dividerKey: 'hr'});
        delta.insert('\n');
      case TextNode():
        _writeText(delta, node);
      default:
        _writeMarkdownLine(delta, node);
    }
  }

  /// [node] as one line of Markdown under [markdownKey], or nothing if Markdown can't express it either.
  void _writeMarkdownLine(Delta delta, DocumentNode node) {
    final line = markdown.writeNode(node);
    if (line == null) return;
    delta.insert({markdownKey: line});
    delta.insert('\n');
  }

  void _writeText(Delta delta, TextNode node) {
    final block = _blockAttributes(node);
    final blockAttributes = block.isEmpty ? null : block;
    final isCode = node.getMetadataValue(NodeMetadata.blockType) == codeAttribution;

    final text = node.text;
    final plainText = text.toPlainText();
    if (plainText.isNotEmpty) {
      for (final span in text.computeAttributionSpans()) {
        final inline = isCode ? const <String, Object?>{} : _inlineAttributes(span.attributions);
        final inlineAttributes = inline.isEmpty ? null : inline;
        // Span ends are inclusive.
        var start = span.start;
        for (var i = span.start; i <= span.end; i++) {
          final character = plainText[i];
          if (character != '\n' && character != '\r') continue;

          if (i > start) delta.insert(plainText.substring(start, i), inlineAttributes);
          // A line break inside a node ends a Quill line, which carries the node's block attributes. Breaks are
          // counted as the importer reads them: "\r\n" (even across spans) and a lone "\r" are one break each.
          if (character == '\r' || i == 0 || plainText[i - 1] != '\r') delta.insert('\n', blockAttributes);
          start = i + 1;
        }
        if (start <= span.end) delta.insert(plainText.substring(start, span.end + 1), inlineAttributes);
      }
    }
    delta.insert('\n', blockAttributes);
  }

  static Map<String, Object?> _blockAttributes(TextNode node) {
    final attributes = <String, Object?>{};
    final int indent;
    switch (node) {
      case ListItemNode():
        attributes['list'] = node.type == ListItemType.ordered ? 'ordered' : 'bullet';
        indent = node.indent;
      case TaskNode():
        attributes['list'] = node.isComplete ? 'checked' : 'unchecked';
        indent = node.indent;
      case ParagraphNode():
        final Attribution? blockType = node.getMetadataValue(NodeMetadata.blockType);
        // Code blocks hold plain, unindented, unaligned text.
        if (blockType == codeAttribution) return {'code-block': true};

        final level = Heading.levelOf(blockType);
        if (level != null) attributes['header'] = level;
        if (blockType == blockquoteAttribution) attributes['blockquote'] = true;
        indent = node.indent;
      default:
        indent = 0;
    }

    final String? align = node.getMetadataValue(TextNodeMetadata.textAlign);
    if (align != null && align != 'left') attributes['align'] = align;
    final clamped = indent.clamp(0, MarkdownFormat.maxIndent);
    if (clamped > 0) attributes['indent'] = clamped;
    return attributes;
  }

  static Map<String, Object?> _inlineAttributes(Set<Attribution> attributions) {
    final attributes = <String, Object?>{};
    for (final attribution in attributions) {
      if (attribution == boldAttribution) {
        attributes['bold'] = true;
      } else if (attribution == italicsAttribution) {
        attributes['italic'] = true;
      } else if (attribution == underlineAttribution) {
        attributes['underline'] = true;
      } else if (attribution == strikethroughAttribution) {
        attributes['strike'] = true;
      } else if (attribution == codeAttribution) {
        attributes['code'] = true;
      } else if (attribution is ColorAttribution) {
        attributes['color'] = QuillColor.format(attribution.color);
      } else if (attribution is BackgroundColorAttribution) {
        attributes['background'] = QuillColor.format(attribution.color);
      } else if (attribution is ScriptAttribution) {
        attributes['script'] = attribution.type == ScriptAttribution.typeSuper ? 'super' : 'sub';
      } else if (attribution is LinkAttribution) {
        attributes['link'] = attribution.plainTextUri;
      }
    }
    return attributes;
  }
}
