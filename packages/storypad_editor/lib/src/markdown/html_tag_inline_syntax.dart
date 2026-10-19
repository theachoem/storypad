import 'package:markdown/markdown.dart' as md;

/// Recognizes a literal `<tag attr="…">…</tag>` in inline Markdown source and turns it into a structured
/// [md.Element], recursively parsing its content as more inline Markdown (so tags nest, and `**bold**` works inside
/// them).
///
/// The content runs to the closing tag that balances the opening one, so the same tag nests too
/// (`<u>a<u>b</u>c</u>`, or a color inside another color). Without one, the opening tag is plain text.
class HtmlTagInlineSyntax extends md.InlineSyntax {
  HtmlTagInlineSyntax(this.tagName)
    : _openOrClose = RegExp('<$tagName$_attributes\\s*>|</$tagName>', caseSensitive: false),
      _close = RegExp('</$tagName>', caseSensitive: false),
      super('<$tagName($_attributes)\\s*>', caseSensitive: false);

  final String tagName;

  static const _attributes = r'(?:\s+[a-zA-Z-]+="[^"]*")*';
  static const _lessThan = 0x3C;
  static final _attributePattern = RegExp(r'([a-zA-Z-]+)="([^"]*)"');

  /// Opening and closing tags of this name, for finding the closing tag that balances an opening one.
  final RegExp _openOrClose;

  /// A closing tag of this name: without one ahead, an opening tag can't close (checked first, so a long line of
  /// unclosed tags isn't scanned tag by tag for each).
  final RegExp _close;

  /// Matches the opening tag (as [pattern]), then consumes through its balancing closing tag -- the base class only
  /// consumes what [pattern] matched, and a pattern can't count nesting.
  @override
  bool tryMatch(md.InlineParser parser, [int? startMatchPos]) {
    final start = startMatchPos ?? parser.pos;
    if (parser.source.codeUnitAt(start) != _lessThan) return false;
    final open = pattern.matchAsPrefix(parser.source, start);
    if (open == null) return false;

    if (_close.allMatches(parser.source, open.end).isEmpty) return false;

    var depth = 1;
    for (final tag in _openOrClose.allMatches(parser.source, open.end)) {
      depth += tag[0]!.startsWith('</') ? -1 : 1;
      if (depth > 0) continue;

      parser.writeText();
      final content = parser.source.substring(open.end, tag.start);
      final element = md.Element(tagName, md.InlineParser(content, parser.document).parse());
      for (final attribute in _attributePattern.allMatches(open[1] ?? '')) {
        element.attributes[attribute[1]!.toLowerCase()] = attribute[2]!;
      }
      parser.addNode(element);
      parser.consume(tag.end - start);
      return true;
    }
    return false;
  }

  /// Unused: [tryMatch] does the matching, since the match runs past what [pattern] covers.
  @override
  bool onMatch(md.InlineParser parser, Match match) => false;
}
