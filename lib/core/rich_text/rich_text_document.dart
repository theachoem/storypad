/// A page body as the app reads it outside the editor's own API: its size and plain text.
abstract class RichTextDocument {
  /// The document's length in text offsets (each block's characters, 1 for an embed, plus one for its line break).
  int get length;

  /// Gets plain text representation (no formatting)
  String toPlainText();
}
