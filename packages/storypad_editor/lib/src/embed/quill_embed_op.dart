import 'package:meta/meta.dart';

import 'story_embed_attribute.dart';

/// A Quill Delta embed insert op, as an embed reads it in [StoryEmbedCodec.fromQuill].
///
/// e.g. `{"insert": {"media": "images/1.jpg|images/2.jpg"}, "attributes": {"custom-embed-size": "max"}}` becomes
/// `QuillEmbedOp(key: 'media', insert: {'media': ...}, attributes: {'custom-embed-size': 'max'})`.
@immutable
final class QuillEmbedOp {
  const QuillEmbedOp({required this.key, required this.insert, this.attributes = const {}});

  /// The insert key the embed was matched on (one of its [StoryEmbedCodec.quillKeys]).
  final String key;

  /// The whole insert map. Usually `{key: value}`.
  final Map<String, Object?> insert;

  /// The op's attributes (e.g. `custom-embed-alignment`), empty if it had none.
  final Map<String, Object?> attributes;

  /// The value under [key], e.g. `"images/1.jpg|images/2.jpg"`.
  Object? get value => insert[key];

  /// Reads a typed attribute, falling back to [StoryEmbedAttribute.fallback] when it's absent or unrecognized.
  A attribute<A extends Object>(StoryEmbedAttribute<A> attribute) => attribute.readQuill(this);

  /// The op in Quill's JSON shape, e.g. for lossless preservation by the unknown embed.
  Map<String, Object?> toJson() => {'insert': insert, if (attributes.isNotEmpty) 'attributes': attributes};

  @override
  String toString() => 'QuillEmbedOp(${toJson()})';
}
