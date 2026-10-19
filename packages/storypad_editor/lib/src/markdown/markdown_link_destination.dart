import 'package:super_editor/super_editor.dart';

import 'inline_markdown_reader.dart';

/// Link destinations as Markdown writes and reads them back.
class MarkdownLinkDestination {
  const MarkdownLinkDestination._();

  static final _canonical = <String, String>{};

  /// An `&` that starts what Markdown reads as a character reference (`&copy;`, `&#169;`, `&#xA9;`), even in a
  /// destination. A wider net than the real entity names: `&amp;` for any other `&` still reads back as `&`.
  static final _referenceStart = RegExp(r'&(?=#[0-9]{1,7};|#[xX][0-9a-fA-F]{1,6};|[A-Za-z][A-Za-z0-9]{1,31};)');

  /// A Markdown link destination for [url]: bare when it needs no escaping, otherwise in the `<…>` form. In both:
  /// - A backslash is written `%5C`, what Markdown percent-encodes it to anyway. Written as is, it would escape the
  ///   character after it (or the closing `>`); and doubled, package:markdown drops it before punctuation (`\\.` reads
  ///   as `.`), against CommonMark.
  /// - An `&` that would start a character reference is written `&amp;`, so `?q=&copy;` stays `&copy;` and doesn't
  ///   read back as `©`; any other `&` (e.g. `?a=1&b=2`) is written as is.
  static String of(String url) {
    url = url.replaceAll(r'\', '%5C').replaceAll(_referenceStart, '&amp;');
    if (url.isNotEmpty && !RegExp(r'[\s<>()]').hasMatch(url)) return url;
    final encoded = url.replaceAll('<', '%3C').replaceAll('>', '%3E').replaceAll('\n', '%0A').replaceAll('\r', '%0D');
    return '<$encoded>';
  }

  /// [url] as it reads back after being written with [of] (Markdown percent-encodes some characters, e.g. spaces).
  static String canonical(String url) {
    return _canonical.putIfAbsent(url, () {
      final parsed = const InlineMarkdownReader().read('[x](${of(url)})');
      final link = parsed.getAllAttributionsAt(0).whereType<LinkAttribution>().firstOrNull;
      return link?.plainTextUri ?? url;
    });
  }
}
