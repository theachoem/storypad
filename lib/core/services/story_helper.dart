import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/quill_service.dart';

class StoryHelper {
  static T? getElementAtIndex<T>(Iterable<T> list, int index) {
    if (index >= 0 && list.length > index) return list.toList()[index];
    return null;
  }

  static bool hasDataWritten(StoryContentDbModel content) {
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

  static Future<StoryContentDbModel> buildContent(
    StoryContentDbModel draftContent,
    Map<int, QuillController> quillControllers,
  ) async {
    final pages = pagesData(draftContent, quillControllers).values.toList();
    return await compute(_buildContent, {
      'draft_content': draftContent,
      'updated_pages': pages,
    });
  }

  static String plainText(MapEntry<int, QuillController> e) {
    try {
      return e.value.getPlainText();
    } catch (e) {
      return "";
    }
  }

  static Map<int, List<dynamic>> pagesData(
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

  static StoryContentDbModel _buildContent(Map<String, dynamic> params) {
    StoryContentDbModel draftContent = params['draft_content'];
    List<List<dynamic>> updatedPages = params['updated_pages'];

    final metadata = [
      draftContent.title,
      ...updatedPages.map((e) => Document.fromJson(e).toPlainText()),
    ].join("\n");

    return draftContent.copyWith(
      plainText: QuillService.toPlainText(Document.fromJson(updatedPages.first).root),
      pages: updatedPages,
      metadata: metadata,
    );
  }

  static Future<Map<int, QuillController>> buildQuillControllers(
    StoryContentDbModel content, {
    required bool readOnly,
  }) async {
    final Map<int, QuillController> quillControllers = {};
    List<Document> documents = await StoryHelper.buildDocuments(content.pages);
    for (int i = 0; i < documents.length; i++) {
      quillControllers[i] = QuillController(
        document: documents[i],
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: readOnly,
      );
    }

    return quillControllers;
  }

  static Future<Document> buildDocument(List<dynamic>? document) async {
    return compute(_buildDocument, document);
  }

  static Future<List<Document>> buildDocuments(List<List<dynamic>>? pages) {
    return compute(_buildDocuments, pages);
  }

  static Document _buildDocument(List<dynamic>? document) {
    if (document != null && document.isNotEmpty) return Document.fromJson(document);
    return Document();
  }

  static List<Document> _buildDocuments(List<List<dynamic>>? pages) {
    if (pages == null || pages.isEmpty == true) return [];
    return pages.map((page) => _buildDocument(page)).toList();
  }

  static Future<bool> hasDataWrittenFromController({
    required StoryContentDbModel draftContent,
    required Map<int, QuillController> quillControllers,
  }) async {
    final content = await StoryHelper.buildContent(draftContent, quillControllers);
    return hasDataWritten(content);
  }

  static Future<bool> hasChanges({
    required StoryContentDbModel draftContent,
    required Map<int, QuillController> quillControllers,
    required StoryContentDbModel latestChange,
    bool ignoredEmpty = true,
  }) async {
    final content = await StoryHelper.buildContent(draftContent, quillControllers);
    if (!ignoredEmpty && !hasDataWritten(content)) return false;
    return content.hasChanges(latestChange);
  }

  static Future<bool> shouldRevert({
    required StoryDbModel currentStory,
    required StoryDbModel initialStory,
  }) async {
    return compute(_shouldRevert, {
      'currentStory': currentStory,
      'initialStory': initialStory,
    });
  }

  static bool _shouldRevert(Map<String, dynamic> params) {
    StoryDbModel currentStory = params['currentStory'];
    StoryDbModel initialStory = params['initialStory'];

    Map<String, dynamic> currentStoryJson = currentStory.toJson()
      ..remove('updated_at')
      ..remove('changes');
    currentStoryJson['latest_change'] = currentStory.latestChange?.toJson()
      ?..remove('id')
      ..remove('created_at')
      ..remove('plain_text')
      ..remove('metadata');

    Map<String, dynamic> initialStoryJson = initialStory.toJson()
      ..remove('updated_at')
      ..remove('changes');
    initialStoryJson['latest_change'] = initialStory.latestChange?.toJson()
      ?..remove('id')
      ..remove('created_at')
      ..remove('plain_text')
      ..remove('metadata');

    return jsonEncode(currentStoryJson) == jsonEncode(initialStoryJson);
  }
}
