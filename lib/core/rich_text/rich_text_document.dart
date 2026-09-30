/// A page body as the app reads it outside the editor's own API: its plain text.
abstract class RichTextDocument {
  /// Gets plain text representation (no formatting)
  String toPlainText();

  /// The plain text after the page title (see `StoryCodec.pageBodyOf`).
  String bodyPlainText();
}
