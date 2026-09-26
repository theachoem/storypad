import 'dart:ui' show Color;

import 'package:super_editor/super_editor.dart';

import 'inline_markdown_reader.dart';

/// Writes [AttributedText] as one line of inline Markdown.
///
/// Formats with native Markdown syntax use it (`**bold**`, `*italic*`, `~~strike~~`, `` `code` ``, `[link](url)`);
/// the rest use inline HTML, which CommonMark passes through (`<u>`, `<span style="color:…">`,
/// `<mark style="background-color:…">`, `<sup>`, `<sub>`). A hard line break (`\n`) is written as `<br>`, so a text
/// block always stays on one Markdown line; line breaks carry no formatting.
///
/// **Self-verifying.** CommonMark's emphasis rules reject some delimiter placements (e.g. `**(a)**b` or `** a**` are
/// not bold). Rather than approximating those rules, every line is parsed back with [InlineMarkdownReader]; if the
/// result differs from the input, the line is rewritten with HTML tags (`<strong>`, `<em>`, `<del>`) instead of
/// delimiters, which always parse exactly.
///
/// Unsupported attributions (fonts, spelling marks, composing regions, …) are dropped; their text is kept.
class InlineMarkdownWriter {
  const InlineMarkdownWriter();

  /// Writes [text] as inline Markdown. Set [escapeHash] inside a heading, where a trailing `#` run would otherwise
  /// be read as a closing sequence.
  String write(AttributedText text, {bool escapeHash = false}) {
    final plainText = text.toPlainText();
    if (plainText.isEmpty) return '';

    final runs = _runs(text, plainText);
    final preferred = _render(runs, useDelimiters: true, escapeHash: escapeHash);
    if (_roundTrips(preferred, text, plainText)) return preferred;

    return _render(runs, useDelimiters: false, escapeHash: escapeHash);
  }

  /// Whether [markdown] parses back to text equal to [original] (after canonicalization).
  bool _roundTrips(String markdown, AttributedText original, String plainText) {
    final parsed = const InlineMarkdownReader().read(markdown);
    return inlineTextEquals(parsed, original);
  }

  /// Splits the text into runs of identical (supported) attributions. Line breaks become their own attribution-free
  /// runs.
  List<_Run> _runs(AttributedText text, String plainText) {
    final runs = <_Run>[];
    for (var i = 0; i < plainText.length; i++) {
      final character = plainText[i];
      final attributions = character == '\n' ? const <Attribution>{} : supportedAttributionsAt(text, i);
      final last = runs.isEmpty ? null : runs.last;
      if (last != null && character != '\n' && !last.isLineBreak && _sameSet(last.attributions, attributions)) {
        last.buffer.write(character);
      } else {
        runs.add(_Run(attributions, character == '\n')..buffer.write(character));
      }
    }
    return runs;
  }

  String _render(List<_Run> runs, {required bool useDelimiters, required bool escapeHash}) {
    final out = _Output();
    final stack = <_OpenTag>[];

    void closeTo(int length) {
      while (stack.length > length) {
        out.write(stack.removeLast().close);
      }
    }

    for (final run in runs) {
      if (run.isLineBreak) {
        closeTo(0);
        out.write('<br>');
        continue;
      }

      final wanted = run.attributions;

      // Keep the longest prefix of open tags that are still wanted; close the rest (reopening any that were only in
      // the way). Code is never on the stack: it's innermost, so each run writes its own code span.
      var keep = 0;
      while (keep < stack.length && wanted.contains(stack[keep].attribution)) {
        keep++;
      }
      closeTo(keep);

      for (final attribution in _ordered(wanted.where((a) => !stack.any((tag) => tag.attribution == a)))) {
        if (attribution == codeAttribution) continue; // Written with the text below.
        final tag = _tagFor(attribution, useDelimiters: useDelimiters);
        // "!" directly before a link's "[" would turn the link into an image.
        if (attribution is LinkAttribution) out.escapeTrailingBang();
        stack.add(tag);
        out.write(tag.open);
      }

      final text = run.buffer.toString();
      if (wanted.contains(codeAttribution)) {
        out.write(_codeSpan(text), isCodeSpan: true);
      } else {
        out.write(escapeText(text, escapeHash: escapeHash, afterCodeSpan: out.endsWithCodeSpan));
      }
    }
    closeTo(0);

    return out.toString();
  }

  /// Attributions in nesting order, outermost first: link, then the styles, with code last (innermost).
  static List<Attribution> _ordered(Iterable<Attribution> attributions) =>
      attributions.toList()..sort((a, b) => _priority(a).compareTo(_priority(b)));

  static int _priority(Attribution attribution) {
    if (attribution is LinkAttribution) return 0;
    if (attribution == boldAttribution) return 1;
    if (attribution == italicsAttribution) return 2;
    if (attribution == strikethroughAttribution) return 3;
    if (attribution == underlineAttribution) return 4;
    if (attribution is BackgroundColorAttribution) return 5;
    if (attribution is ColorAttribution) return 6;
    if (attribution is ScriptAttribution) return 7;
    return 8; // code
  }

  static _OpenTag _tagFor(Attribution attribution, {required bool useDelimiters}) {
    if (attribution == boldAttribution) {
      return useDelimiters ? _OpenTag(attribution, '**', '**') : _OpenTag(attribution, '<strong>', '</strong>');
    }
    if (attribution == italicsAttribution) {
      return useDelimiters ? _OpenTag(attribution, '*', '*') : _OpenTag(attribution, '<em>', '</em>');
    }
    if (attribution == strikethroughAttribution) {
      return useDelimiters ? _OpenTag(attribution, '~~', '~~') : _OpenTag(attribution, '<del>', '</del>');
    }
    if (attribution == underlineAttribution) return _OpenTag(attribution, '<u>', '</u>');
    if (attribution is BackgroundColorAttribution) {
      return _OpenTag(attribution, '<mark style="background-color:#${colorToCssHex(attribution.color)}">', '</mark>');
    }
    if (attribution is ColorAttribution) {
      return _OpenTag(attribution, '<span style="color:#${colorToCssHex(attribution.color)}">', '</span>');
    }
    if (attribution is ScriptAttribution) {
      return attribution.type == ScriptAttribution.typeSuper
          ? _OpenTag(attribution, '<sup>', '</sup>')
          : _OpenTag(attribution, '<sub>', '</sub>');
    }
    if (attribution is LinkAttribution) {
      final destination = linkDestination(canonicalLinkDestination(attribution.plainTextUri));
      return _OpenTag(attribution, '[', ']($destination)');
    }
    throw StateError('Unsupported attribution $attribution');
  }

  /// A code span holding [code] verbatim: the fence is one backtick longer than the longest backtick run inside, and
  /// padded with spaces when CommonMark would otherwise strip or merge the content's edges.
  static String _codeSpan(String code) {
    final longestRun = RegExp(
      '`+',
    ).allMatches(code).fold(0, (longest, match) => match[0]!.length > longest ? match[0]!.length : longest);
    final fence = '`' * (longestRun + 1);
    final allSpaces = code.trim().isEmpty;
    final needsPadding =
        code.startsWith('`') || code.endsWith('`') || (!allSpaces && code.startsWith(' ') && code.endsWith(' '));
    return needsPadding ? '$fence $code $fence' : '$fence$code$fence';
  }

  static bool _sameSet(Set<Attribution> a, Set<Attribution> b) => a.length == b.length && a.containsAll(b);
}

/// Formatting attributions the Markdown codec can represent.
bool isSupportedAttribution(Attribution attribution) =>
    attribution == boldAttribution ||
    attribution == italicsAttribution ||
    attribution == strikethroughAttribution ||
    attribution == underlineAttribution ||
    attribution == codeAttribution ||
    attribution is LinkAttribution ||
    attribution is ColorAttribution ||
    attribution is BackgroundColorAttribution ||
    attribution is ScriptAttribution;

/// The supported attributions at [offset].
Set<Attribution> supportedAttributionsAt(AttributedText text, int offset) =>
    text.getAllAttributionsAt(offset).where(isSupportedAttribution).toSet();

/// Whether two texts are equal as far as Markdown can tell: same characters, and the same supported attributions on
/// every character except line breaks (which carry no formatting in Markdown).
bool inlineTextEquals(AttributedText a, AttributedText b) {
  final plainText = a.toPlainText();
  if (plainText != b.toPlainText()) return false;

  for (var i = 0; i < plainText.length; i++) {
    if (plainText[i] == '\n') continue;
    final attributionsA = supportedAttributionsAt(a, i).map(_canonical).toSet();
    final attributionsB = supportedAttributionsAt(b, i).map(_canonical).toSet();
    if (attributionsA.length != attributionsB.length || !attributionsA.containsAll(attributionsB)) return false;
  }
  return true;
}

/// Link destinations are compared the way Markdown normalizes them.
Attribution _canonical(Attribution attribution) =>
    attribution is LinkAttribution ? LinkAttribution(canonicalLinkDestination(attribution.plainTextUri)) : attribution;

/// Escapes plain text for inline Markdown: backslashes for Markdown punctuation, character references for `<`, `>`,
/// `&` (so no text can form an HTML tag, and no tag-matching syntax can be fooled by an escaped `</tag>`) and for
/// backticks.
///
/// Set [afterCodeSpan] when [text] directly follows a code span: package:markdown won't decode a character reference
/// right after a backtick (and a backslash-escaped backtick breaks a following code span), so a leading reference is
/// separated from the span by a `<wbr>` (an invisible line-break opportunity), which reads back as nothing.
String escapeText(String text, {bool escapeHash = false, bool afterCodeSpan = false}) {
  final buffer = StringBuffer();
  if (afterCodeSpan && text.isNotEmpty && const {'<', '>', '&', '`'}.contains(text[0])) {
    buffer.write('<wbr>');
  }
  for (final rune in text.runes) {
    final character = String.fromCharCode(rune);
    switch (character) {
      case '\\' || '*' || '_' || '~' || '[' || ']':
        buffer.write('\\$character');
      // A reference, not `\``: a backslash-escaped backtick right before a code span confuses package:markdown.
      case '`':
        buffer.write('&#96;');
      case '#' when escapeHash:
        buffer.write(r'\#');
      case '<':
        buffer.write('&lt;');
      case '>':
        buffer.write('&gt;');
      case '&':
        buffer.write('&amp;');
      default:
        buffer.write(character);
    }
  }
  return buffer.toString();
}

/// A Markdown link destination for [url]: bare when it needs no escaping, otherwise in the `<…>` form.
String linkDestination(String url) {
  if (url.isNotEmpty && !RegExp(r'[\s<>()\\]').hasMatch(url)) return url;
  final encoded = url.replaceAll('<', '%3C').replaceAll('>', '%3E').replaceAll('\n', '%0A').replaceAll('\r', '%0D');
  return '<$encoded>';
}

final _canonicalDestinations = <String, String>{};

/// [url] as it reads back after being written with [linkDestination] (Markdown percent-encodes some characters,
/// e.g. spaces).
String canonicalLinkDestination(String url) {
  return _canonicalDestinations.putIfAbsent(url, () {
    final parsed = const InlineMarkdownReader().read('[x](${linkDestination(url)})');
    final link = parsed.getAllAttributionsAt(0).whereType<LinkAttribution>().firstOrNull;
    return link?.plainTextUri ?? url;
  });
}

/// Formats [color] as lowercase, zero-padded `rrggbbaa` (CSS order, alpha last).
String colorToCssHex(Color color) {
  String byte(double channel) => (channel * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '${byte(color.r)}${byte(color.g)}${byte(color.b)}${byte(color.a)}';
}

/// The line being written, tracking what the next write needs to know about the previous one.
class _Output {
  final _buffer = StringBuffer();
  String _pending = '';
  bool endsWithCodeSpan = false;

  void write(String text, {bool isCodeSpan = false}) {
    if (text.isEmpty) return;
    _buffer.write(_pending);
    _pending = text;
    endsWithCodeSpan = isCodeSpan;
  }

  /// Escapes a trailing, unescaped `!` (one preceded by an even number of backslashes).
  void escapeTrailingBang() {
    if (!_pending.endsWith('!')) return;

    var backslashes = 0;
    for (var i = _pending.length - 2; i >= 0 && _pending[i] == '\\'; i--) {
      backslashes++;
    }
    if (backslashes.isEven) {
      _pending = '${_pending.substring(0, _pending.length - 1)}\\!';
    }
  }

  @override
  String toString() => '$_buffer$_pending';
}

class _Run {
  _Run(this.attributions, this.isLineBreak);

  final Set<Attribution> attributions;
  final bool isLineBreak;
  final buffer = StringBuffer();
}

class _OpenTag {
  _OpenTag(this.attribution, this.open, this.close);

  final Attribution attribution;
  final String open;
  final String close;
}
