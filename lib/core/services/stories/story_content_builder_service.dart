import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';

class StoryContentBuilderService {
  static Future<StoryContentDbModel> call({
    required StoryContentDbModel draftContent,
    required List<QuillController> quillControllers,
    required List<TextEditingController> titleControllers,
  }) async {
    final pages = _pagesData(draftContent, quillControllers, titleControllers);

    return await compute(_buildContent, {
      'draft_content': draftContent,
      'updated_pages': pages,
    });
  }

  static StoryContentDbModel _buildContent(Map<String, dynamic> params) {
    StoryContentDbModel draftContent = params['draft_content'];
    List<StoryPageDbModel> updatedPages = params['updated_pages'];

    final metadata = [
      ...updatedPages.map((e) => e.title),
      ...updatedPages.map((e) => e.plainText),
    ].join("\n");

    return draftContent.copyWith(
      title: updatedPages.firstOrNull?.title,
      plainText: updatedPages.firstOrNull?.plainText,
      pages: null,
      richPages: updatedPages,
      metadata: metadata,
    );
  }

  static List<StoryPageDbModel> _pagesData(
    StoryContentDbModel draftContent,
    List<QuillController> quillControllers,
    List<TextEditingController> titleControllers,
  ) {
    List<StoryPageDbModel> pages = [];

    if (draftContent.richPages != null) {
      for (int pageIndex = 0; pageIndex < draftContent.richPages!.length; pageIndex++) {
        final oldPage = draftContent.richPages?[pageIndex];
        final document = quillControllers.elementAtOrNull(pageIndex)?.document;
        final title = titleControllers.elementAtOrNull(pageIndex)?.text.trim() ?? oldPage?.title?.trim();

        final page = StoryPageDbModel(
          title: title != null && title.isNotEmpty ? title : null,
          plainText: document != null ? QuillRootToPlainTextService.call(document.root) : oldPage?.plainText,
          body: document?.toDelta().toJson() ?? oldPage?.body,
          feeling: oldPage?.feeling,
        );

        pages.add(page);
      }
    }

    return pages;
  }
}
