import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/stories/story_content_pages_to_document_service.dart';

class StoryContentToQuillControllersService {
  static Future<Map<int, QuillController>> call(
    StoryContentDbModel content, {
    required bool readOnly,
  }) async {
    final Map<int, QuillController> quillControllers = {};
    List<Document> documents = await StoryContentPagesToDocumentService.call(content.pages);

    for (int i = 0; i < documents.length; i++) {
      quillControllers[i] = QuillController(
        document: documents[i],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: readOnly,
      );
    }

    return quillControllers;
  }
}
