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

  // ========================================================================
  // Serialization
  // ========================================================================

  /// The page as Markdown for storage, title included (its first block, a heading). A page the user didn't change
  /// returns the Markdown it was opened with, untouched.
  String serialize();

  // ========================================================================
  // Embed Operations
  // ========================================================================

  /// Inserts an embed at the current cursor position (the last one while the editor has none, else the end).
  ///
  /// [embedType]: The embed type key (e.g., 'media', 'audio')
  /// [value]: The embed value (e.g., file path or pipe-delimited paths)
  /// [attributes]: Optional formatting attributes to apply (e.g., size, alignment)
  void insertEmbed({
    required String embedType,
    required String value,
    Map<String, dynamic>? attributes,
  });
}
