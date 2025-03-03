import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/stories/story_has_data_written_service.dart';
import 'package:storypad/core/services/stories/story_content_builder_service.dart';

class StoryHasChangedService {
  static Future<bool> call({
    required StoryContentDbModel draftContent,
    required Map<int, QuillController> quillControllers,
    required StoryContentDbModel latestChange,
    bool ignoredEmpty = true,
  }) async {
    final content = await StoryContentBuilderService.call(draftContent, quillControllers);
    if (!ignoredEmpty && !StoryHasDataWrittenService.callByContent(content)) return false;
    return content.hasChanges(latestChange);
  }
}
