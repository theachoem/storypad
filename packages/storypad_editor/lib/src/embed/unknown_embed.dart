import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'quill_embed_op.dart';
import 'story_embed_codec.dart';
import 'story_html_element.dart';

/// Content no registered embed understood, preserved losslessly so opening and saving a story never destroys it --
/// e.g. an embed added by a newer app version, or a malformed value an embed rejected.
@immutable
sealed class UnknownEmbedValue {
  const UnknownEmbedValue();
}

/// A Quill embed op no registered embed imported. [op] is the whole op, attributes included, in Quill's JSON shape.
///
/// Stored in Markdown as `<sp-unknown data-op="base64(json(op))"></sp-unknown>` -- base64 because the payload is
/// arbitrary JSON.
final class UnknownQuillEmbed extends UnknownEmbedValue {
  UnknownQuillEmbed(Map<String, Object?> op) : op = Map.unmodifiable(op);

  final Map<String, Object?> op;

  /// The op's insert key, e.g. `mystery-embed`, or `null` if the op has no map insert.
  String? get key {
    final insert = op['insert'];
    return insert is Map && insert.isNotEmpty ? '${insert.keys.first}' : null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UnknownQuillEmbed && const DeepCollectionEquality().equals(op, other.op);

  @override
  int get hashCode => const DeepCollectionEquality().hash(op);

  @override
  String toString() => 'UnknownQuillEmbed($op)';
}

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

/// The built-in catch-all embed. Always registered last: it imports every Quill embed op nothing else claimed, and
/// the Markdown codec hands it every embed line nothing else could read.
final class UnknownEmbedCodec extends StoryEmbedCodec<UnknownEmbedValue> {
  const UnknownEmbedCodec();

  static const embedType = 'unknown';
  static const htmlTag = 'sp-unknown';

  @override
  String get type => embedType;

  @override
  Set<String> get htmlTags => const {htmlTag};

  /// Accepts any op -- the codec only routes ops here that no other embed claimed.
  @override
  UnknownEmbedValue fromQuill(QuillEmbedOp op) => UnknownQuillEmbed(op.toJson());

  /// Decodes an `<sp-unknown data-op>` element. Anything else (including a malformed payload) returns `null`, and
  /// the codec then keeps the line verbatim as an [UnknownHtmlEmbed].
  @override
  UnknownEmbedValue? fromHtml(StoryHtmlElement element) {
    if (element.tag != htmlTag) return null;

    final data = element['data-op'];
    if (data == null) return null;

    try {
      final decoded = jsonDecode(utf8.decode(base64Decode(data)));
      if (decoded is! Map<String, Object?>) return null;
      return UnknownQuillEmbed(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  StoryHtmlElement toHtml(UnknownEmbedValue value) {
    return switch (value) {
      UnknownQuillEmbed(:final op) => StoryHtmlElement(
        htmlTag,
        attributes: {'data-op': base64Encode(utf8.encode(jsonEncode(op)))},
      ),
      UnknownHtmlEmbed(:final html) => StoryHtmlElement.raw(html),
    };
  }
}
