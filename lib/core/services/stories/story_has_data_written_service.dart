import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/stories/story_content_builder_service.dart';

class StoryHasDataWrittenService {
  static Future<bool> callByController({
    required StoryContentDbModel draftContent,
    required Map<int, QuillController> quillControllers,
  }) async {
    final content = await StoryContentBuilderService.call(
      draftContent: draftContent,
      quillControllers: quillControllers,
    );

    return callByContent(content);
  }

  static bool callByContent(StoryContentDbModel content) {
    List<List<dynamic>> pagesClone = content.pages ?? [];
    List<List<dynamic>> pages = [...pagesClone];

    pages.removeWhere((items) {
      bool empty = items.isEmpty;
      if (items.length == 1) {
        dynamic first = items.first;
        if (first is Map) {
          dynamic insert = items.first['insert'];
          if (insert is String) return insert.trim().isEmpty;
        }
      }
      return empty;
    });

    bool emptyPages = pages.isEmpty;
    String title = content.title ?? "";

    bool hasNoDataWritten = emptyPages && title.trim().isEmpty;
    return !hasNoDataWritten;
  }
}
