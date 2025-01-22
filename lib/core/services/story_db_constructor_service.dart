import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';

class StoryDbConstructorService {
  static List<String> changesToRawChanges(StoryDbModel story) {
    List<String> existingRawChanges = story.rawChanges ?? [];

    // when all changes are loaded, use loaded all changes instead.
    if (story.allChanges != null) {
      return changesToStrs(story.allChanges!);
    } else {
      return [
        ...existingRawChanges,
        changesToStrs([story.latestChange!]).first,
      ];
    }
  }

  static List<StoryContentDbModel> rawChangesToChanges(List<String> changes) {
    Map<String, StoryContentDbModel> items = {};
    for (String str in changes) {
      String decoded = HtmlCharacterEntities.decode(str);
      dynamic json = jsonDecode(decoded);
      String id = json['id'].toString();
      items[id] ??= StoryContentDbModel.fromJson(json);
    }
    return items.values.toList();
  }

  static List<String> changesToStrs(List<StoryContentDbModel> changes) {
    return changes.map((e) {
      Map<String, dynamic> json = e.toJson();
      String encoded = jsonEncode(json);
      return HtmlCharacterEntities.encode(encoded);
    }).toList();
  }

  static Future<StoryDbModel> loadAllChanges(StoryDbModel story) async {
    if (story.rawChanges != null) {
      List<StoryContentDbModel> changes =
          await compute(StoryDbConstructorService.rawChangesToChanges, story.rawChanges!);
      story = story.copyWith(allChanges: changes);
    }
    return story;
  }
}
