import 'dart:convert';

import 'package:html_character_entities/html_character_entities.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';

class StoryChangesToRawService {
  static List<String> call(StoryDbModel story) {
    List<String> existingRawChanges = story.rawChanges ?? [];

    // when all changes are loaded, use loaded all changes instead.
    if (story.allChanges != null) {
      return _changesToStrs(story.allChanges!);
    } else {
      final latestChange = _changesToStrs([story.latestChange!]).first;
      return existingRawChanges.contains(latestChange) ? existingRawChanges : [...existingRawChanges, latestChange];
    }
  }

  static List<String> _changesToStrs(List<StoryContentDbModel> changes) {
    return changes.map((e) {
      Map<String, dynamic> json = e.toJson();
      String encoded = jsonEncode(json);
      return HtmlCharacterEntities.encode(encoded);
    }).toList();
  }
}
