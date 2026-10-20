import 'package:markdown/markdown.dart' as md;
import 'package:super_editor/super_editor.dart';

import 'css_color.dart';
import 'html_tag_inline_syntax.dart';

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

  /// Never throws: if the Markdown can't be parsed into consistent formatting, the source text is kept as-is.
  AttributedText read(String markdown) {
    if (markdown.isEmpty) return AttributedText();
    try {
      return parseInlineMarkdown(
        markdown,
        inlineMarkdownSyntaxes: _markdownSyntaxes,
        inlineHtmlSyntaxes: _htmlSyntaxes,
      );
    } catch (_) {
      return AttributedText(markdown);
    }
  }

  static final _markdownSyntaxes = <md.InlineSyntax>[
    md.StrikethroughSyntax(),
    _BrTagSyntax(),
    _WbrTagSyntax(),
    for (final tag in const ['u', 'span', 'mark', 'sup', 'sub', 'strong', 'em', 'del', 's', 'code'])
      HtmlTagInlineSyntax(tag),
  ];

  static const _htmlSyntaxes = <InlineHtmlSyntax>[
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

  static AttributedText? _brHtmlSyntax(md.Element element, AttributedText text) =>
      element.tag == 'br' ? AttributedText('\n') : null;

  static AttributedText? _wrap(AttributedText text, Attribution attribution) {
    // An empty element (e.g. `<u></u>`) has nothing to attribute.
    if (text.length == 0) return text;
    final range = SpanRange(0, text.length - 1);
    // A conflicting inner value (a link inside a link, <sub> inside <sup>) wins; adding would throw.
    final conflicts = text.getAttributionSpansInRange(
      attributionFilter: (existing) => existing.id == attribution.id && !existing.canMergeWith(attribution),
      range: range,
    );
    if (conflicts.isNotEmpty) return text;
    return text..addAttribution(attribution, range);
  }

  static AttributedText? _boldHtmlSyntax(md.Element element, AttributedText text) =>
      element.tag == 'strong' ? _wrap(text, boldAttribution) : null;

  static AttributedText? _italicHtmlSyntax(md.Element element, AttributedText text) =>
      element.tag == 'em' ? _wrap(text, italicsAttribution) : null;

  static AttributedText? _underlineHtmlSyntax(md.Element element, AttributedText text) =>
      element.tag == 'u' ? _wrap(text, underlineAttribution) : null;

  static AttributedText? _strikethroughHtmlSyntax(md.Element element, AttributedText text) =>
      element.tag == 'del' || element.tag == 's' ? _wrap(text, strikethroughAttribution) : null;

  static AttributedText? _codeHtmlSyntax(md.Element element, AttributedText text) =>
      element.tag == 'code' ? _wrap(text, codeAttribution) : null;

  static AttributedText? _anchorHtmlSyntax(md.Element element, AttributedText text) {
    if (element.tag != 'a') return null;
    final href = element.attributes['href'] ?? '';
    return _wrap(text, LinkAttribution(href, Uri.tryParse(href)));
  }

  static AttributedText? _colorHtmlSyntax(md.Element element, AttributedText text) {
    if (element.tag != 'span') return null;
    final color = CssColor.fromStyle(element.attributes['style'], RegExp(r'(?<![-\w])color'));
    return color == null ? null : _wrap(text, ColorAttribution(color));
  }

  static AttributedText? _backgroundHtmlSyntax(md.Element element, AttributedText text) {
    if (element.tag != 'mark') return null;
    final color = CssColor.fromStyle(element.attributes['style'], RegExp(r'(?<![-\w])background-color'));
    return color == null ? null : _wrap(text, BackgroundColorAttribution(color));
  }

  static AttributedText? _scriptHtmlSyntax(md.Element element, AttributedText text) {
    return switch (element.tag) {
      'sup' => _wrap(text, const ScriptAttribution.superscript()),
      'sub' => _wrap(text, const ScriptAttribution.subscript()),
      _ => null,
    };
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
