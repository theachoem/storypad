/// Interface for serializing and deserializing rich text content.
///
/// This abstraction allows converting between:
/// - Storage format (JSON)
/// - Display format (Document)
/// - Export formats (Plain text, Markdown)
///
/// Implementations handle format-specific conversion logic.
abstract class RichTextSerializer {
  /// Serializes rich text to JSON for database storage
  ///
  /// [content] can be a Document or raw Delta operations
  List<dynamic> serialize(dynamic content);

  /// Deserializes JSON from database to Document
  ///
  /// Compatible with output from [serialize()]
  dynamic deserialize(List<dynamic> json);

  /// Converts rich text content to plain text (no formatting)
  ///
  /// [deltaOps] is the JSON array of operations
  /// [includeEmbeds] determines if embed placeholders are included
  String toPlainText(
    List<dynamic> deltaOps, {
    bool includeEmbeds = false,
  });

  /// Converts rich text content to Markdown
  ///
  /// [deltaOps] is the JSON array of operations
  /// [includeEmbeds] determines if embed references are included
  String toMarkdown(
    List<dynamic> deltaOps, {
    bool includeEmbeds = false,
  });

  /// Converts Markdown to rich text format
  ///
  /// Returns JSON array compatible with [deserialize()]
  List<dynamic> fromMarkdown(String markdown);

  /// Extracts embed references from content
  ///
  /// [deltaOps] is the JSON array of operations
  /// [embedType] filters by type (e.g., 'image', 'audio', or null for all)
  ///
  /// Returns list of embed data (e.g., file paths)
  List<String> extractEmbeds(
    List<dynamic> deltaOps, {
    String? embedType,
  });
}
