import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';

class StoryContentHelper {
  static StoryContentDbModel stringToContent(String str) {
    String decoded = HtmlCharacterEntities.decode(str);
    dynamic json = jsonDecode(decoded);

    StoryContentDbModel content = StoryContentDbModel.fromJson(json);
    return convertPagesToRichPages(content);
  }

  static String contentToString(StoryContentDbModel content) {
    Map<String, dynamic> json = content.toJson();
    String encoded = jsonEncode(json);
    return HtmlCharacterEntities.encode(encoded);
  }

  // TODO: remove this method when ready.
  // This is a low level method to make sure view get rich pages instead of pages when using.
  static StoryContentDbModel convertPagesToRichPages(StoryContentDbModel content) {
    // ignore: deprecated_member_use_from_same_package
    if (content.pages != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      content = content.copyWith(
        pages: null,
        richPages: List.generate(
          // ignore: deprecated_member_use_from_same_package
          content.pages?.length ?? 0,
          (index) => StoryPageDbModel(
            id: now + index,
            title: index == 0 ? content.title : null,
            // ignore: deprecated_member_use_from_same_package
            body: content.pages![index],
          ),
        ),
      );
    }

    return content;
  }

  static StoryPreferencesDbModel decodePreferences(
    String? preferences, {
    bool? showDayCount,
  }) {
    StoryPreferencesDbModel? decodedDreferences;

    if (preferences != null) {
      try {
        decodedDreferences = StoryPreferencesDbModel.fromJson(jsonDecode(preferences));
      } catch (e) {
        debugPrint(".decodePreferences error: $e");
      }
    }

    decodedDreferences ??= StoryPreferencesDbModel.create();
    if (showDayCount != null) decodedDreferences = decodedDreferences.copyWith(showDayCount: showDayCount);
    return decodedDreferences;
  }
}
