/// Abstract interface for rich text document representation.
///
/// This abstraction decouples StoryPad from specific rich text formats
/// and allows swapping implementations.
///
/// A document represents the complete rich text content including:
/// - Text with formatting (bold, italic, colors, etc.)
/// - Blocks (paragraphs, lists, blockquotes, code blocks)
/// - Embeds (images, audio, custom content)
abstract class RichTextDocument {
  /// Creates a document from serialized JSON format
  ///
  /// JSON structure depends on implementation (e.g., Quill Delta operations)
  factory RichTextDocument.fromJson(List<dynamic> json) {
    throw UnimplementedError('RichTextDocument.fromJson must be implemented by adapter');
  }

  /// Creates an empty document
  factory RichTextDocument.empty() {
    throw UnimplementedError('RichTextDocument.empty must be implemented by adapter');
  }

  /// Returns the length of the document in characters
  int get length;

  /// Serializes the document to JSON format for storage
  ///
  /// Returns format compatible with [fromJson()]
  List<dynamic> toJson();

  /// Gets plain text representation (no formatting)
  String toPlainText();
}
