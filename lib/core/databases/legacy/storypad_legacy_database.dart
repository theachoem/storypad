import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/preferences_box.dart';
import 'package:storypad/core/databases/legacy/storypad_legacy_story_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/services/quill/quill_root_to_plain_text_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:sqflite/sqflite.dart' as sqlite;

class StorypadLegacyDatabase {
  sqlite.Database? _database;
  bool get exist => _database != null;

  Future<String?> _getDatabasePath() async {
    String newPath = join(await sqlite.getDatabasesPath(), "write_story.db");
    String oldPath = join(await getApplicationDocumentsDirectory().then((e) => e.path), "write_story.db");

    if (File(newPath).existsSync()) return newPath;
    if (File(oldPath).existsSync()) return oldPath;

    return null;
  }

  Future<sqlite.Database?> _openDatabase(String databasePath) async {
    String? databasePath = await _getDatabasePath();
    if (databasePath == null) return null;

    try {
      return sqlite.openDatabase(databasePath, onOpen: (_) {}, version: 3);
    } catch (e) {
      debugPrint("🐛 Open database dailed: $e");
    }

    return null;
  }

  String singleQuote = "▘";
  Future<(bool, String)> transferToObjectBoxIfNotYet() async {
    if (!kStoryPad) return (true, 'Only for StoryPad');

    String sharePreferenceKey = "LegacyStoryPadImported";
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool? imported = sharedPreferences.getBool(sharePreferenceKey);
    if (imported == true) return (true, 'Already Imported');

    String? databasePath = await _getDatabasePath();
    if (databasePath == null) return (true, 'File is not exist!');

    _database ??= await _openDatabase(databasePath);
    if (!exist) return (true, 'Could not open database $databasePath');

    List<Map<dynamic, dynamic>>? storyRows = await _database?.query('story');
    List<Map<dynamic, dynamic>>? userInfoRows = await _database?.query('user_info');
    if (storyRows == null || storyRows.isEmpty) return (true, 'Database empty!');

    try {
      List<StorypadLegacyStoryModel> storypadStories = storyRows.map((json) {
        StorypadLegacyStoryModel story = StorypadLegacyStoryModel.fromJson(json);
        if (story.paragraph != null) {
          String? paragraph = story.paragraph != null ? HtmlCharacterEntities.decode(story.paragraph!) : null;
          return story.copyWith(paragraph: paragraph?.replaceAll(singleQuote, "'"));
        } else {
          return story;
        }
      }).toList();

      List<StoryDbModel> stories = [];
      for (StorypadLegacyStoryModel storypadStory in storypadStories) {
        Document? document;

        if (storypadStory.paragraph != null) {
          dynamic quill = jsonDecode(storypadStory.paragraph!);
          document = Document.fromJson(quill);
        }

        final content = StoryContentDbModel.create(createdAt: storypadStory.createOn).copyWith(
          title: storypadStory.title,
          plainText: document != null ? QuillRootToPlainTextService.call(document.root) : null,
          richPages: [
            StoryPageDbModel(
              title: storypadStory.title,
              feeling: storypadStory.feeling,
              body: document?.toDelta().toJson(),
            )
          ],
        );

        stories.add(StoryDbModel(
          type: PathType.docs,
          id: storypadStory.createOn.millisecondsSinceEpoch,
          starred: storypadStory.isFavorite,
          feeling: storypadStory.feeling,
          preferences: null,
          year: storypadStory.forDate.year,
          month: storypadStory.forDate.month,
          day: storypadStory.forDate.day,
          hour: storypadStory.createOn.hour,
          minute: storypadStory.forDate.minute,
          second: storypadStory.forDate.second,
          updatedAt: storypadStory.updateOn ?? storypadStory.createOn,
          createdAt: storypadStory.createOn,
          lastSavedDeviceId: null,
          tags: [],
          assets: [],
          movedToBinAt: null,
          latestContent: content,
          draftContent: null,
        ));
      }

      for (StoryDbModel story in stories) {
        await StoryDbModel.db.set(story, runCallbacks: false);
      }

      if (userInfoRows != null && userInfoRows.isNotEmpty) {
        String? nickname = userInfoRows.firstOrNull?['nickname'];
        if (nickname != null) PreferencesBox().nickname.set(nickname);
      }

      await sharedPreferences.setBool(sharePreferenceKey, true);
      return (true, 'DB: ${storyRows.length}, StoryPad: ${storypadStories.length}, StoryPad v2: ${stories.length}');
    } catch (e) {
      return (false, e.toString());
    }
  }
}
