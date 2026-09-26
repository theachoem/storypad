import 'dart:ui' show Color;

import 'package:markdown/markdown.dart' as md;
import 'package:super_editor/super_editor.dart';

/// Parses one line of inline Markdown (as written by `InlineMarkdownWriter`, or typed by hand) into
/// [AttributedText].
///
/// Built on `package:markdown`'s CommonMark inline parser (emphasis, code spans, links, escapes, entities, hard
/// breaks) plus the inline HTML tags the writer uses for formats Markdown lacks. `package:markdown` has no mechanism
/// for recognizing literal HTML tags in inline text, so each tag gets its own [HtmlTagInlineSyntax].
///
/// Deliberately excludes super_editor's own non-standard inline syntaxes (`¬underline¬`, single-`~` strikethrough),
/// so ordinary text containing those characters isn't misread as formatting.
class InlineMarkdownReader {
  const InlineMarkdownReader();

  AttributedText read(String markdown) {
    if (markdown.isEmpty) return AttributedText();
    return parseInlineMarkdown(markdown, inlineMarkdownSyntaxes: _markdownSyntaxes, inlineHtmlSyntaxes: _htmlSyntaxes);
  }
}

final _markdownSyntaxes = <md.InlineSyntax>[
  md.StrikethroughSyntax(),
  _BrTagSyntax(),
  _WbrTagSyntax(),
  for (final tag in const ['u', 'span', 'mark', 'sup', 'sub', 'strong', 'em', 'del', 's']) HtmlTagInlineSyntax(tag),
];

const _htmlSyntaxes = <InlineHtmlSyntax>[
  _brHtmlSyntax,
  _boldHtmlSyntax,
  _italicHtmlSyntax,
  _underlineHtmlSyntax,
  _strikethroughHtmlSyntax,
  _codeHtmlSyntax,
  _anchorHtmlSyntax,
  _colorHtmlSyntax,
  _backgroundHtmlSyntax,
  _scriptHtmlSyntax,
];

/// Recognizes a literal `<tag attr="…">…</tag>` in inline Markdown source and turns it into a structured
/// [md.Element], recursively parsing its content as more inline Markdown (so tags nest, and `**bold**` works inside
/// them).
class HtmlTagInlineSyntax extends md.InlineSyntax {
  HtmlTagInlineSyntax(this.tagName)
    : super('<$tagName((?:\\s+[a-zA-Z-]+="[^"]*")*)\\s*>(.*?)</$tagName>', caseSensitive: false);

  final String tagName;

  static final _attributePattern = RegExp(r'([a-zA-Z-]+)="([^"]*)"');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element(tagName, md.InlineParser(match[2] ?? '', parser.document).parse());
    for (final attribute in _attributePattern.allMatches(match[1] ?? '')) {
      element.attributes[attribute[1]!.toLowerCase()] = attribute[2]!;
    }
    parser.addNode(element);
    return true;
  }
}

/// `<br>` (the writer's hard line break) as a void element.
class _BrTagSyntax extends md.InlineSyntax {
  _BrTagSyntax() : super(r'<br\s*/?>', caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty('br'));
    return true;
  }
}

/// `<wbr>`, which the writer uses as an invisible separator. Reads back as nothing.
class _WbrTagSyntax extends md.InlineSyntax {
  _WbrTagSyntax() : super(r'<wbr\s*/?>', caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty('wbr'));
    return true;
  }
}

AttributedText? _brHtmlSyntax(md.Element element, AttributedText text) =>
    element.tag == 'br' ? AttributedText('\n') : null;

AttributedText? _wrap(AttributedText text, Attribution attribution) {
  // An empty element (e.g. `<u></u>`) has nothing to attribute.
  if (text.length == 0) return text;
  return text..addAttribution(attribution, SpanRange(0, text.length - 1));
}

AttributedText? _boldHtmlSyntax(md.Element element, AttributedText text) =>
    element.tag == 'strong' ? _wrap(text, boldAttribution) : null;

AttributedText? _italicHtmlSyntax(md.Element element, AttributedText text) =>
    element.tag == 'em' ? _wrap(text, italicsAttribution) : null;

AttributedText? _underlineHtmlSyntax(md.Element element, AttributedText text) =>
    element.tag == 'u' ? _wrap(text, underlineAttribution) : null;

AttributedText? _strikethroughHtmlSyntax(md.Element element, AttributedText text) =>
    element.tag == 'del' || element.tag == 's' ? _wrap(text, strikethroughAttribution) : null;

AttributedText? _codeHtmlSyntax(md.Element element, AttributedText text) =>
    element.tag == 'code' ? _wrap(text, codeAttribution) : null;

AttributedText? _anchorHtmlSyntax(md.Element element, AttributedText text) {
  if (element.tag != 'a') return null;
  final href = element.attributes['href'] ?? '';
  return _wrap(text, LinkAttribution(href, Uri.tryParse(href)));
}

AttributedText? _colorHtmlSyntax(md.Element element, AttributedText text) {
  if (element.tag != 'span') return null;
  final color = _styleColor(element.attributes['style'], RegExp(r'(?<![-\w])color'));
  return color == null ? null : _wrap(text, ColorAttribution(color));
}

AttributedText? _backgroundHtmlSyntax(md.Element element, AttributedText text) {
  if (element.tag != 'mark') return null;
  final color = _styleColor(element.attributes['style'], RegExp(r'(?<![-\w])background-color'));
  return color == null ? null : _wrap(text, BackgroundColorAttribution(color));
}

AttributedText? _scriptHtmlSyntax(md.Element element, AttributedText text) {
  return switch (element.tag) {
    'sup' => _wrap(text, const ScriptAttribution.superscript()),
    'sub' => _wrap(text, const ScriptAttribution.subscript()),
    _ => null,
  };
}

/// Reads a `#rrggbbaa` (or `#rrggbb`) color for [property] from a CSS `style` attribute.
Color? _styleColor(String? style, RegExp property) {
  if (style == null) return null;

  // Exactly 6 or 8 hex digits, not {6,8}: a 7-digit match would be invalid.
  final match = RegExp('${property.pattern}\\s*:\\s*#([0-9a-fA-F]{8}|[0-9a-fA-F]{6})\\b').firstMatch(style);
  final hex = match?.group(1);
  if (hex == null) return null;

  int channel(int start) => int.parse(hex.substring(start, start + 2), radix: 16);
  return Color.fromARGB(hex.length == 8 ? channel(6) : 255, channel(0), channel(2), channel(4));
}
