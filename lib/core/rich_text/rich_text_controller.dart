import 'package:flutter/widgets.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';

/// Abstract interface for rich text editor controllers.
///
/// This abstraction allows StoryPad to work with different rich text editor
/// implementations without tight coupling to a specific library.
///
/// Implementations should provide:
/// - Document management (load, save, serialize)
/// - Text editing operations (insert, replace, delete)
/// - Formatting operations (bold, italic, colors, lists, etc.)
/// - Cursor/selection management
/// - Embed insertion (images, audio, custom blocks)
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

  /// Inserts text at the current cursor position
  void insertText(String text) {
    final index = selection.baseOffset;
    replaceText(index, 0, text, TextSelection.collapsed(offset: index + text.length));
  }

  /// Deletes text in the current selection
  void deleteSelection() {
    if (!selection.isCollapsed) {
      replaceText(
        selection.start,
        selection.end - selection.start,
        '',
        selection.copyWith(extentOffset: selection.start),
      );
    }
  }

  // ========================================================================
  // Formatting Operations
  // ========================================================================

  /// Applies text formatting to the current selection.
  ///
  /// [attributeKey] can be: 'bold', 'italic', 'underline', 'strike', 'color',
  /// 'background', 'link', etc.
  ///
  /// [value] is the attribute value (e.g., Color for 'color', bool for 'bold')
  void formatSelection(String attributeKey, dynamic value);

  /// Removes formatting from the current selection
  void removeFormat(String attributeKey);

  /// Gets the current formatting attributes at the cursor position
  Map<String, dynamic> getSelectionStyle();

  /// Gets all text styles in the current selection
  List<Map<String, dynamic>> getAllSelectionStyles();

  // ========================================================================
  // Cursor Management
  // ========================================================================

  /// Moves cursor to the specified position
  void moveCursorToPosition(int position) {
    selection = TextSelection.collapsed(offset: position);
  }

  /// Moves cursor to the end of the document
  void moveCursorToEnd() {
    final length = document.length;
    selection = TextSelection.collapsed(offset: length);
  }

  /// Moves cursor to the beginning of the document
  void moveCursorToStart() {
    selection = const TextSelection.collapsed(offset: 0);
  }

  // ========================================================================
  // Embed Operations
  // ========================================================================

  /// Inserts an embed (image, audio, custom block) at current cursor position
  ///
  /// [embedType] can be: 'image', 'audio', 'date', or custom types
  /// [embedData] is type-specific data (e.g., file path for images)
  void insertEmbed(String embedType, dynamic embedData) {
    final index = selection.baseOffset;
    replaceText(
      index,
      0,
      {embedType: embedData},
      TextSelection.collapsed(offset: index + 1),
    );
  }

  // ========================================================================
  // Content Extraction
  // ========================================================================

  /// Gets plain text representation of the document (no formatting)
  String getPlainText();

  /// Gets markdown representation of the document
  String toMarkdown();

  /// Serializes the document to JSON format for storage
  ///
  /// Returns format compatible with [RichTextDocument.fromJson()]
  List<dynamic> serialize();

  // ========================================================================
  // Lifecycle
  // ========================================================================

  /// Disposes resources used by the controller
  @override
  void dispose();
}
