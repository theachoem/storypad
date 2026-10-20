import 'dart:convert';

import 'quill_embed_op.dart';
import 'story_embed_codec.dart';
import 'story_html_element.dart';
import 'unknown_embed_value.dart';

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

  /// A preserved Quill op is written back verbatim, attributes included. A preserved Markdown line has no Quill form,
  /// so it's written as Markdown (see [StoryEmbedCodec.toQuill]).
  @override
  QuillEmbedOp? toQuill(UnknownEmbedValue value) {
    if (value is! UnknownQuillEmbed) return null;

    final insert = value.op['insert'];
    final attributes = value.op['attributes'];
    if (insert is! Map || insert.isEmpty) return null;
    return QuillEmbedOp(
      key: '${insert.keys.first}',
      insert: Map<String, Object?>.from(insert),
      attributes: attributes is Map ? Map<String, Object?>.from(attributes) : const {},
    );
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
