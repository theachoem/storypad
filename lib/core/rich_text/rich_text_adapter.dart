import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_adapter.dart';
import 'package:storypad/core/types/page_layout_type.dart';

/// Abstract interface for rich text editor adapter.
///
/// This interface isolates all implementation-specific APIs behind a clean boundary.
/// Business logic only interacts with this adapter, never with concrete implementations.
abstract class RichTextAdapter {
  // ========================================================================
  // Widget Builders
  // ========================================================================

  /// Builds the rich text editor widget.
  Widget buildEditor({
    required BuildContext context,
    required RichTextController controller,
    required FocusNode focusNode,
    required bool readOnly,
    required StoryContentDbModel storyContent,
    PageLayoutType? layoutType,
    VoidCallback? onChanged,
    VoidCallback? onGoToEdit,
  });

  /// Builds the rich text toolbar widget.
  Widget buildToolbar({
    required BuildContext context,
    required RichTextController controller,
  });

  // ========================================================================
  // Factory Methods
  // ========================================================================

  /// Creates a controller for a page stored as [markdown] (title included, as its leading heading).
  RichTextController createController({
    required String markdown,
    required TextSelection selection,
    required bool readOnly,
  });

  // ========================================================================
  // Embed Operations
  // ========================================================================

  /// Inserts a media embed (photo or video) at the current cursor position.
  ///
  /// [controller]: The rich text controller
  /// [mediaPath]: Relative path to the image or video file
  void insertMedia({
    required RichTextController controller,
    required String mediaPath,
  });

  /// Inserts an audio embed at the current cursor position.
  ///
  /// [controller]: The rich text controller
  /// [audioPath]: Relative path to the audio file
  void insertAudio({
    required RichTextController controller,
    required String audioPath,
  });
}

/// Global singleton instance for rich text editor adapter.
///
/// Business logic should ONLY interact with the editor through this instance.
///
/// Example usage:
/// ```dart
/// // In editor view:
/// editorAdapter.buildEditor(context: context, controller: controller, ...)
///
/// // In bottom sheet:
/// editorAdapter.insertMedia(controller: controller, mediaPath: path)
/// ```
///
/// Stories are edited with storypad_editor (super_editor) and stored as Markdown.
final RichTextAdapter editorAdapter = StoryPadEditorRichTextAdapter();
