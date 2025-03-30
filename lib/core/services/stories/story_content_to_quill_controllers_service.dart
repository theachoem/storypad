import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/stories/story_content_pages_to_document_service.dart';

class StoryContentToQuillControllersService {
  static Future<List<QuillController>> call(
    StoryContentDbModel content, {
    required bool readOnly,
    List<QuillController>? existingControllers,
  }) async {
    final List<QuillController> quillControllers = [];

    if (existingControllers != null) {
      for (int i = 0; i < existingControllers.length; i++) {
        quillControllers.add(QuillController(
          document: existingControllers[i].document,
          selection: existingControllers[i].selection,
        ));
      }
    } else {
      List<Document> documents = await StoryContentPagesToDocumentService.call(content.richPages);
      for (int i = 0; i < documents.length; i++) {
        quillControllers.add(QuillController(
          document: documents[i],
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: readOnly,
        ));
      }
    }

    return quillControllers;
  }
}
