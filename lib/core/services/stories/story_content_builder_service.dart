import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';

class StoryContentBuilderService {
  static Future<StoryContentDbModel> call(
    StoryContentDbModel draftContent,
    Map<int, QuillController> quillControllers,
  ) async {
    final pages = _pagesData(draftContent, quillControllers).values.toList();
    return await compute(_buildContent, {
      'draft_content': draftContent,
      'updated_pages': pages,
    });
  }

  static StoryContentDbModel _buildContent(Map<String, dynamic> params) {
    StoryContentDbModel draftContent = params['draft_content'];
    List<List<dynamic>> updatedPages = params['updated_pages'];

    final metadata = [
      draftContent.title,
      ...updatedPages.map((e) => Document.fromJson(e).toPlainText()),
    ].join("\n");

    return draftContent.copyWith(
      plainText: QuillRootToPlainTextService.call(Document.fromJson(updatedPages.first).root),
      pages: updatedPages,
      metadata: metadata,
    );
  }

  static Map<int, List<dynamic>> _pagesData(
    StoryContentDbModel draftContent,
    Map<int, QuillController> quillControllers,
  ) {
    Map<int, List<dynamic>> documents = {};
    if (draftContent.pages != null) {
      for (int pageIndex = 0; pageIndex < draftContent.pages!.length; pageIndex++) {
        List<dynamic>? quillDocument =
            quillControllers.containsKey(pageIndex) ? quillControllers[pageIndex]!.document.toDelta().toJson() : null;
        documents[pageIndex] = quillDocument ?? draftContent.pages![pageIndex];
      }
    }
    return documents;
  }
}
