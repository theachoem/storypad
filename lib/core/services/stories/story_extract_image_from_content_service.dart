import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';

class StoryExtractImageFromContentService {
  static List<String> call(StoryContentDbModel? content) {
    List<String> images = [];

    try {
      for (dynamic e in content?.pages?.expand((e) => e) ?? []) {
        final insert = e['insert'];
        if (insert is Map) {
          for (MapEntry<dynamic, dynamic> e in insert.entries) {
            if (e.value != null && e.value.isNotEmpty) {
              images.add(e.value);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) rethrow;
    }

    return images;
  }
}
