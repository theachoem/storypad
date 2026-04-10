import 'package:flutter/widgets.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';

/// Abstract interface for rich text editor controllers.
///
/// This abstraction allows StoryPad to work with different rich text editor
/// implementations without tight coupling to a specific library.
///
/// Core responsibilities:
/// - Document management and serialization
/// - Text selection management
/// - Content extraction (plain text, etc.)
abstract class RichTextController extends ChangeNotifier {
  /// The underlying document containing the rich text content
  RichTextDocument get document;

  /// The current text selection/cursor position
  TextSelection get selection;
  set selection(TextSelection value);

  /// Whether the editor is in read-only mode
  bool get readOnly;

  // ========================================================================
  // Text Editing Operations
  // ========================================================================

  /// Replaces text at [index] with [length] replaced by [data].
  ///
  /// [data] can be:
  /// - String: Plain text
  /// - Map: Embed data (e.g., {"image": "path/to/image.jpg"})
  ///
  /// [textSelection] is the new cursor position after replacement.
  void replaceText(
    int index,
    int length,
    Object data,
    TextSelection? textSelection,
  );

  // ========================================================================
  // Content Extraction & Serialization
  // ========================================================================

  /// Gets plain text representation of the document (no formatting)
  String getPlainText();

  /// Serializes the document to JSON format for storage
  ///
  /// Returns format compatible with [RichTextDocument.fromJson()]
  List<dynamic> serialize();

  // ========================================================================
  // Embed Operations
  // ========================================================================

  /// Inserts an embed at the current cursor position.
  ///
  /// [embedType]: The embed type key (e.g., 'image', 'audio')
  /// [value]: The embed value (e.g., file path or pipe-delimited paths)
  /// [attributes]: Optional formatting attributes to apply (e.g., size, alignment)
  void insertEmbed({
    required String embedType,
    required String value,
    Map<String, dynamic>? attributes,
  });

  /// Replaces an embed's data at [offset] while preserving its existing attributes.
  ///
  /// This is used when the embed value changes (e.g., album paths updated)
  /// but the formatting (alignment, size) should be kept.
  ///
  /// [offset]: The document offset of the embed
  /// [length]: The length of the embed (typically 1)
  /// [embedType]: The embed type key (e.g., 'image')
  /// [value]: The new embed value
  void replaceEmbed({
    required int offset,
    required int length,
    required String embedType,
    required String value,
  });
}
