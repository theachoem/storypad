import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';

class StoryContentHelper {
  /// Reads content stored by [contentToString] -- or, from earlier versions, stored HTML-entity-encoded: that
  /// encoding always escaped `"`, so it never starts with `{"` the way plain JSON does.
  static StoryContentDbModel stringToContent(String str) {
    String decoded = str.startsWith('{"') ? str : HtmlCharacterEntities.decode(str);
    dynamic json = jsonDecode(decoded);

    StoryContentDbModel content = StoryContentDbModel.fromJson(json);
    return convertPagesToRichPages(content);
  }

  static String contentToString(StoryContentDbModel content) {
    Map<String, dynamic> json = content.toJson();
    // Plain JSON. Earlier versions stored it HTML-entity-encoded, which doesn't read back exactly: decoding also turns
    // any entity *in the content* into its character (repeatedly, `&amp;nbsp;` included) -- and Markdown pages use
    // entities on purpose (`&nbsp;` for a blank line, `&#32;` for kept spaces).
    return jsonEncode(json);
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
          (index) => StoryPageDbModel.legacy(
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

  static StoryPreferencesDbModel decodePreferences(String? preferences) {
    StoryPreferencesDbModel? decodedDreferences;

    if (preferences != null) {
      try {
        decodedDreferences = StoryPreferencesDbModel.fromJson(jsonDecode(preferences));
      } catch (e) {
        debugPrint(".decodePreferences error: $e");
      }
    }

    decodedDreferences ??= StoryPreferencesDbModel.create();
    return decodedDreferences;
  }
}
