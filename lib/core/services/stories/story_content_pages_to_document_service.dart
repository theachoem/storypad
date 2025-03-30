import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';

class StoryContentPagesToDocumentService {
  static Future<List<Document>> call(List<StoryPageDbModel>? richPages) {
    return compute(_buildDocuments, richPages);
  }

  static Future<Document> forSinglePage(StoryPageDbModel richPage) async {
    return compute(_buildDocument, richPage);
  }

  static List<Document> _buildDocuments(List<StoryPageDbModel>? richPages) {
    if (richPages == null || richPages.isEmpty == true) return [];
    return richPages.map((page) => _buildDocument(page)).toList();
  }

  static Document _buildDocument(StoryPageDbModel page) {
    return page.body != null ? Document.fromJson(page.body!) : Document();
  }
}
