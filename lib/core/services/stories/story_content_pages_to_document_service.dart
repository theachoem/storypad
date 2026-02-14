import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/rich_text/rich_text.dart';

class StoryContentPagesToDocumentService {
  static Future<List<RichTextDocument>> forMultiplePages(List<StoryPageDbModel>? richPages) {
    return compute(_buildDocuments, richPages);
  }

  static List<RichTextDocument> forMultiplePagesSync(List<StoryPageDbModel>? richPages) {
    return _buildDocuments(richPages);
  }

  static Future<RichTextDocument> forSinglePage(StoryPageDbModel richPage) async {
    return compute(_buildDocument, richPage);
  }

  static RichTextDocument forSinglePageSync(StoryPageDbModel richPage) {
    return _buildDocument(richPage);
  }

  static List<RichTextDocument> _buildDocuments(List<StoryPageDbModel>? richPages) {
    if (richPages == null || richPages.isEmpty == true) return [];
    return richPages.map((page) => _buildDocument(page)).toList();
  }

  static RichTextDocument _buildDocument(StoryPageDbModel page) {
    return page.body != null ? editorAdapter.createDocument(json: page.body!) : editorAdapter.createEmptyDocument();
  }
}
