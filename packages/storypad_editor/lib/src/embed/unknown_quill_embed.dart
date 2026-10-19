part of 'unknown_embed_value.dart';

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
