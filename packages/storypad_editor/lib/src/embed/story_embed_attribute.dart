import 'package:meta/meta.dart';

import 'quill_embed_op.dart';
import 'story_html_element.dart';

/// A typed embed attribute with one definition covering both formats an embed speaks: the Quill op attribute it's
/// imported from, and the HTML attribute it's stored as in Markdown.
///
/// ```dart
/// enum EmbedAlignment { none, left, center, right }
///
/// const alignment = StoryEmbedAttribute<EmbedAlignment>.enumeration(
///   quillKey: 'custom-embed-alignment',
///   htmlName: 'data-align',
///   values: {EmbedAlignment.left: 'left', EmbedAlignment.center: 'center', EmbedAlignment.right: 'right'},
///   fallback: EmbedAlignment.none,
/// );
///
/// op.attribute(alignment);       // EmbedAlignment.center, from {"custom-embed-alignment": "center"}
/// element.attribute(alignment);  // EmbedAlignment.center, from data-align="center"
/// alignment.toHtml(value);       // {'data-align': 'center'}, or {} for the fallback
/// ```
///
/// Reading never throws: a missing or unrecognized value reads as [fallback]. Writing omits the fallback, so default
/// values don't clutter the Markdown.
@immutable
final class StoryEmbedAttribute<A extends Object> {
  /// An attribute with custom string conversion. [parse] returns `null` for an unrecognized value.
  const StoryEmbedAttribute({
    required this.htmlName,
    required A? Function(String raw) this._parse,
    required String Function(A value) this._format,
    required this.fallback,
    this.quillKey,
  }) : _values = null;

  /// An attribute backed by a fixed set of values (typically an enum), each with its string form. The [fallback]
  /// doesn't need an entry in [values], since it's never written.
  const StoryEmbedAttribute.enumeration({
    required this.htmlName,
    required Map<A, String> this._values,
    required this.fallback,
    this.quillKey,
  }) : _parse = null,
       _format = null;

  /// The Quill op attribute key, e.g. `custom-embed-alignment`. `null` if the attribute doesn't exist in Quill.
  final String? quillKey;

  /// The HTML attribute name, e.g. `data-align`. Prefer `data-*` names for custom attributes.
  final String htmlName;

  /// The value when the attribute is absent or unrecognized. Never written.
  final A fallback;

  final Map<A, String>? _values;
  final A? Function(String raw)? _parse;
  final String Function(A value)? _format;

  /// Parses a raw string, or returns `null` if it isn't recognized.
  A? parse(String raw) {
    final values = _values;
    if (values == null) return _parse!(raw);

    final trimmed = raw.trim();
    for (final MapEntry(:key, :value) in values.entries) {
      if (value == trimmed) return key;
    }
    return null;
  }

  /// The string form of [value].
  String format(A value) {
    final values = _values;
    if (values == null) return _format!(value);

    final formatted = values[value];
    if (formatted == null) {
      throw ArgumentError.value(value, 'value', 'has no string form in $htmlName\'s values');
    }
    return formatted;
  }

  /// Reads this attribute from a Quill op. Non-string values (e.g. numbers) are parsed from their `toString()`.
  A readQuill(QuillEmbedOp op) {
    final key = quillKey;
    if (key == null) return fallback;

    final raw = op.attributes[key];
    if (raw == null) return fallback;
    return parse(raw is String ? raw : raw.toString()) ?? fallback;
  }

  /// Reads this attribute from an HTML element.
  A readHtml(StoryHtmlElement element) {
    final raw = element.attributes[htmlName];
    if (raw == null) return fallback;
    return parse(raw) ?? fallback;
  }

  /// The HTML attributes for [value]: empty for the [fallback], otherwise `{htmlName: format(value)}`. Spread it into
  /// a [StoryHtmlElement]'s attributes.
  Map<String, String> toHtml(A value) => value == fallback ? const {} : {htmlName: format(value)};

  @override
  String toString() => 'StoryEmbedAttribute<$A>($htmlName)';
}
