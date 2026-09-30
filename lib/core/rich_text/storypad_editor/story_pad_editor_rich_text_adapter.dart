import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/rich_text/rich_text_adapter.dart';
import 'package:storypad/core/rich_text/rich_text_controller.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/embed_attributes.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_rich_text_controller.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_editor_toolbar.dart';
import 'package:storypad/core/types/page_layout_type.dart';

/// The story editor on storypad_editor (super_editor): pages load from and save to Markdown.
class StoryPadEditorRichTextAdapter implements RichTextAdapter {
  @override
  List<LocalizationsDelegate> get localizationsDelegates => const [];

  @override
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
    TextStyle? titleStyle,
  }) {
    return StoryPadEditor(
      controller: controller as StoryPadEditorRichTextController,
      focusNode: focusNode,
      readOnly: readOnly,
      storyContent: storyContent,
      layoutType: layoutType,
      onChanged: onChanged,
      onGoToEdit: onGoToEdit,
      titleStyle: titleStyle,
    );
  }

  @override
  Widget buildToolbar({required BuildContext context, required RichTextController controller, Color? backgroundColor}) {
    return StoryPadEditorToolbar(controller: controller as StoryPadEditorRichTextController);
  }

  @override
  RichTextController createController({
    required String markdown,
    required TextSelection selection,
    required bool readOnly,
  }) {
    return StoryPadEditorRichTextController(markdown: markdown, selection: selection, readOnly: readOnly);
  }

  @override
  void insertMedia({required RichTextController controller, required String mediaPath}) {
    controller.insertEmbed(
      embedType: 'media',
      value: mediaPath,
      attributes: embedSize.toQuill(EmbedSize.max),
    );
  }

  @override
  void insertAudio({required RichTextController controller, required String audioPath}) {
    controller.insertEmbed(embedType: 'audio', value: audioPath);
  }
}
