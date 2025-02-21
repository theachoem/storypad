import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';

class StoryDbConstructorService {
  static List<String> changesToRawChanges(StoryDbModel story) {
    List<String> existingRawChanges = story.rawChanges ?? [];

    // when all changes are loaded, use loaded all changes instead.
    if (story.allChanges != null) {
      return changesToStrs(story.allChanges!);
    } else {
      final latestChange = changesToStrs([story.latestChange!]).first;
      return existingRawChanges.contains(latestChange) ? existingRawChanges : [...existingRawChanges, latestChange];
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

  static StoryPreferencesDbModel decodePreferences(StoryObjectBox object) {
    StoryPreferencesDbModel? preferences;

    if (object.preferences != null) {
      try {
        preferences = StoryPreferencesDbModel.fromJson(jsonDecode(object.preferences!));
      } catch (e) {
        debugPrint("$StoryDbConstructorService.decodePreferences error: $e");
      }
    }

    preferences ??= StoryPreferencesDbModel.create();
    if (object.showDayCount != null) preferences = preferences.copyWith(showDayCount: object.showDayCount);
    return preferences;
  }
}
