import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'quill_import_loss_kind.dart';

/// One piece of Quill formatting an import (`StoryCodec.decodeQuill`) drops, found by `StoryCodec.quillImportLosses`.
/// Text and embeds are never dropped; only formatting is.
@immutable
final class QuillImportLoss {
  const QuillImportLoss(this.kind, {required this.line, this.key, this.value});

  final QuillImportLossKind kind;

  /// The 0-based Quill line (count of `\n`s before it) the loss is on.
  final int line;

  /// The attribute key concerned, if any.
  final String? key;

  /// The attribute value concerned, if any.
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is QuillImportLoss &&
      kind == other.kind &&
      line == other.line &&
      key == other.key &&
      const DeepCollectionEquality().equals(value, other.value);

  @override
  int get hashCode => Object.hash(kind, line, key, const DeepCollectionEquality().hash(value));

  @override
  String toString() =>
      'QuillImportLoss(${kind.name}, line $line${key == null ? '' : ', $key'}'
      '${value == null ? '' : ': $value'})';
}
