import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/stories/story_content_builder_service.dart';

class StoryHasDataWrittenService {
  static Future<bool> callByController({
    required StoryContentDbModel draftContent,
    required Map<int, QuillController> quillControllers,
    required Map<int, TextEditingController> titleControllers,
  }) async {
    final content = await StoryContentBuilderService.call(
      draftContent: draftContent,
      quillControllers: quillControllers,
      titleControllers: titleControllers,
    );

    return callByContent(content);
  }

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
