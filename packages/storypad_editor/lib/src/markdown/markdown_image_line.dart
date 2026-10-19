import 'package:markdown/markdown.dart' as md;

/// A line consisting of exactly one Markdown image, `![alt](src)`.
class MarkdownImageLine {
  const MarkdownImageLine({required this.src, required this.alt});

  final String src;
  final String alt;

  /// Reads [line] as one image, or returns `null` when it's anything else.
  static MarkdownImageLine? read(String line) {
    final nodes = md.InlineParser(line.trim(), md.Document(encodeHtml: false)).parse();
    if (nodes.length != 1) return null;

    final node = nodes.single;
    if (node is! md.Element || node.tag != 'img') return null;
    return MarkdownImageLine(src: node.attributes['src'] ?? '', alt: node.attributes['alt'] ?? '');
  }
}
