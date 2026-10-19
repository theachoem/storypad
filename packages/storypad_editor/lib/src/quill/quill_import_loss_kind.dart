import 'quill_import_loss.dart';

/// What kind of Quill formatting an import drops. See [QuillImportLoss].
enum QuillImportLossKind {
  /// An op that isn't a well-formed insert (e.g. a retain/delete, or `attributes` that isn't a map). Skipped.
  invalidOp,

  /// An attribute the importer doesn't read at all, e.g. `font`, `size` or `direction`.
  unsupportedAttribute,

  /// A known attribute with a value it can't read, e.g. `color: "red"`, `header: 7`, `bold: "yes"`.
  invalidAttributeValue,

  /// A known attribute read only partly, e.g. a code block's language (`code-block: "dart"`), or an indent beyond the
  /// maximum.
  attributeValueDropped,

  /// A block format that can't be combined with the line's other block format (e.g. a header on a list line): the
  /// other one wins.
  conflictingBlockFormat,

  /// Alignment on a code line.
  alignmentDropped,

  /// Indent on a code line.
  indentDropped,

  /// Inline formatting inside a code block (code blocks hold plain text).
  formattingInCode,

  /// Block formatting on a line holding an embed: the embed becomes its own block, without it.
  embedLineFormat,
}
