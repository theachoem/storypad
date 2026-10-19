part of 'unknown_embed_value.dart';

/// A Markdown HTML line no registered embed read, kept verbatim so it's written back exactly as it was.
final class UnknownHtmlEmbed extends UnknownEmbedValue {
  const UnknownHtmlEmbed(this.html);

  /// The original single line of HTML.
  final String html;

  /// The line's tag name, or `null` if it doesn't start with one.
  String? get tag => RegExp(r'^<([a-zA-Z][a-zA-Z0-9-]*)').firstMatch(html)?.group(1)?.toLowerCase();

  @override
  bool operator ==(Object other) => identical(this, other) || other is UnknownHtmlEmbed && html == other.html;

  @override
  int get hashCode => html.hashCode;

  @override
  String toString() => 'UnknownHtmlEmbed($html)';
}
