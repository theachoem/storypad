import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/rich_text/flutter_quill/quill_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/rich_text_document.dart';
import 'package:storypad/core/types/page_layout_type.dart';

/// Abstract interface for rich text editor adapter.
///
/// This interface isolates all implementation-specific APIs behind a clean boundary.
/// Business logic only interacts with this adapter, never with concrete implementations.
abstract class RichTextAdapter {
  // ========================================================================
  // Localization
  // ========================================================================

  /// Returns localization delegates required by the editor.
  ///
  /// Add these to MaterialApp's localizationsDelegates:
  /// ```dart
  /// MaterialApp(
  ///   localizationsDelegates: [
  ///     ...otherDelegates,
  ///     ...editorAdapter.localizationsDelegates,
  ///   ],
  /// )
  /// ```
  List<LocalizationsDelegate> get localizationsDelegates;

  // ========================================================================
  // Widget Builders
  // ========================================================================

  /// Builds the rich text editor widget.
  Widget buildEditor({
    required BuildContext context,
    required RichTextController controller,
    required FocusNode focusNode,
    required ScrollController scrollController,
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
    Color? backgroundColor,
  });

  // ========================================================================
  // Factory Methods
  // ========================================================================

  /// Creates a RichTextController from JSON data.
  ///
  /// [json]: Delta JSON from database (`List<dynamic>`)
  /// [selection]: Initial cursor position
  /// [readOnly]: Whether the editor is read-only
  RichTextController createController({
    required List<dynamic> json,
    required TextSelection selection,
    required bool readOnly,
  });

  /// Creates a RichTextController with empty content.
  RichTextController createEmptyController({
    required bool readOnly,
  });

  /// Creates a RichTextDocument from JSON data.
  RichTextDocument createDocument({
    required List<dynamic> json,
  });

  /// Creates an empty RichTextDocument.
  RichTextDocument createEmptyDocument();

  // ========================================================================
  // Embed Operations
  // ========================================================================

  /// Inserts an image embed at the current cursor position.
  ///
  /// [controller]: The rich text controller
  /// [imagePath]: Relative path to the image file
  void insertImage({
    required RichTextController controller,
    required String imagePath,
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
/// // In app.dart:
/// localizationsDelegates: editorAdapter.localizationsDelegates
///
/// // In editor view:
/// editorAdapter.buildEditor(context: context, controller: controller, ...)
///
/// // In bottom sheet:
/// editorAdapter.insertImage(controller: controller, imagePath: path)
/// ```
final RichTextAdapter editorAdapter = QuillRichTextAdapter();
