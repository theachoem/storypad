import 'dart:convert';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';

class StoryRawToChangesService {
  static List<StoryContentDbModel> call(List<String> changes) {
    Map<String, StoryContentDbModel> items = {};
    for (String str in changes) {
      String decoded = HtmlCharacterEntities.decode(str);
      dynamic json = jsonDecode(decoded);
      String id = json['id'].toString();
      items[id] ??= StoryContentDbModel.fromJson(json);
    }
    return items.values.toList();
  }
}
