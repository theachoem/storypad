import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/rich_text/rich_text.dart';
import 'package:storypad/core/services/generate_body_plain_text_service.dart';

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
    _map[richPage.id] = StoryPageObject(
      key: GlobalKey(),
      page: richPage,
      titleController: TextEditingController(text: richPage.title?.trim()),
      bodyController: editorAdapter.createController(
        json: richPage.body ?? [],
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
    final result = await Isolate.run(() {
      final plainTextResult = GenerateBodyPlainTextService.call(content.richPages);
      return plainTextResult?.richPagesWithCounts;
    });

    StoryPageObjectsMap map = StoryPageObjectsMap();

    for (int i = 0; i < (content.richPages?.length ?? 0); i++) {
      final richPage = content.richPages![i];

      final richTextController = editorAdapter.createController(
        json: richPage.body ?? [],
        selection: initialPagesMap?[richPage.id]?.bodyController.selection ?? const TextSelection.collapsed(offset: 0),
        readOnly: readOnly,
      );

      map[richPage.id] = StoryPageObject(
        key: GlobalKey(),
        page: result?[i] ?? richPage,
        titleController: TextEditingController.fromValue(
          TextEditingValue(
            text: richPage.title?.trim() ?? '',
            selection:
                initialPagesMap?[richPage.id]?.titleController.selection ??
                TextSelection.collapsed(offset: richPage.title?.length ?? 0),
          ),
        ),
        bodyController: richTextController,
        bodyScrollController: ScrollController(),
        titleFocusNode: FocusNode(),
        bodyFocusNode: FocusNode(),
      );
    }

    return map;
  }
}
