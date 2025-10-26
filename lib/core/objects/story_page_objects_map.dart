import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';
import 'package:storypad/core/services/stories/story_content_pages_to_document_service.dart';

class StoryPageObjectsMap {
  final Map<int, StoryPageObject> _map = {};

  StoryPageObject? operator [](int key) => _map[key];

  void operator []=(int key, StoryPageObject value) {
    _map[key] = value;
  }

  Iterable<int> get keys => _map.keys;

  StoryPageObject get first => _map.values.first;

  StoryPageObject? remove(Object? key) {
    _map[key]?.dispose();
    return _map.remove(key);
  }

  void dispose() {
    for (final key in [..._map.keys]) {
      remove(key);
    }
  }

  void setTitleVisibleFraction(int key, double visibleFraction) {
    _map[key]?.titleVisibleFraction = visibleFraction;
  }

  void add({
    required StoryPageDbModel richPage,
    required bool readOnly,
  }) async {
    final document = await StoryContentPagesToDocumentService.forSinglePage(richPage);
    _map[richPage.id] = StoryPageObject(
      key: GlobalKey(),
      page: richPage,
      titleController: TextEditingController(text: richPage.title?.trim()),
      bodyController: QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: readOnly,
      ),
      bodyScrollController: ScrollController(),
      titleFocusNode: FocusNode(),
      bodyFocusNode: FocusNode(),
    );
  }

  static Future<StoryPageObjectsMap> fromContent({
    required StoryContentDbModel content,
    required bool readOnly,
    StoryPageObjectsMap? initialPagesMap,
  }) async {
    final documents = await StoryContentPagesToDocumentService.call(content.richPages);
    StoryPageObjectsMap map = StoryPageObjectsMap();

    for (int i = 0; i < documents.length; i++) {
      final richPage = content.richPages![i];

      final quillController = QuillController(
        document: documents[i],
        selection: initialPagesMap?[richPage.id]?.bodyController.selection ?? const TextSelection.collapsed(offset: 0),
        readOnly: readOnly,
      );

      map[richPage.id] = StoryPageObject(
        key: GlobalKey(),
        page: richPage.copyWith(memoryPlainText: QuillRootToPlainTextService.call(quillController.document.root)),
        titleController: TextEditingController.fromValue(
          TextEditingValue(
            text: richPage.title?.trim() ?? '',
            selection:
                initialPagesMap?[richPage.id]?.titleController.selection ??
                TextSelection.collapsed(offset: richPage.title?.length ?? 0),
          ),
        ),
        bodyController: quillController,
        bodyScrollController: ScrollController(),
        titleFocusNode: FocusNode(),
        bodyFocusNode: FocusNode(),
      );
    }

    return map;
  }
}
