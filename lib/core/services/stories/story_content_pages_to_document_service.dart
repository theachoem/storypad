import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';

class StoryContentPagesToDocumentService {
  static Future<List<Document>> call(List<List<dynamic>>? pages) {
    return compute(_buildDocuments, pages);
  }

  // static Future<Document> singlePage(List<dynamic>? document) async {
  //   return compute(_buildDocument, document);
  // }

  static List<Document> _buildDocuments(List<List<dynamic>>? pages) {
    if (pages == null || pages.isEmpty == true) return [];
    return pages.map((page) => _buildDocument(page)).toList();
  }

  static Document _buildDocument(List<dynamic>? document) {
    if (document != null && document.isNotEmpty) return Document.fromJson(document);
    return Document();
  }
}
