import 'package:storypad/core/databases/models/story_content_db_model.dart';

class StoryHasDataWrittenService {
  static bool callByContent(StoryContentDbModel content) {
    List<List<dynamic>> pagesClone = content.richPages?.map((e) => e.body ?? []).toList() ?? [];
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

    bool mainTitleEmpty = (content.title ?? '').trim().isEmpty;
    bool pagesTitleEmpty = (content.richPages ?? []).every((page) => (page.title ?? '').trim().isEmpty) == true;

    bool hasNoDataWritten = emptyPages && mainTitleEmpty && pagesTitleEmpty;
    return !hasNoDataWritten;
  }
}
