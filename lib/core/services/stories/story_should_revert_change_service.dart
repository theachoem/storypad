import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';

class StoryShouldRevertChangeService {
  static Future<bool> call({
    required StoryDbModel currentStory,
    required StoryDbModel initialStory,
  }) async {
    return compute(_shouldRevert, {
      'currentStory': currentStory,
      'initialStory': initialStory,
    });
  }

  static bool _shouldRevert(Map<String, dynamic> params) {
    StoryDbModel currentStory = params['currentStory'];
    StoryDbModel initialStory = params['initialStory'];

    Map<String, dynamic> currentStoryJson = currentStory.toJson()
      ..remove('updated_at')
      ..remove('changes');
    currentStoryJson['latest_change'] = currentStory.latestChange?.toJson()
      ?..remove('id')
      ..remove('created_at')
      ..remove('plain_text')
      ..remove('metadata');

    Map<String, dynamic> initialStoryJson = initialStory.toJson()
      ..remove('updated_at')
      ..remove('changes');
    initialStoryJson['latest_change'] = initialStory.latestChange?.toJson()
      ?..remove('id')
      ..remove('created_at')
      ..remove('plain_text')
      ..remove('metadata');

    return jsonEncode(currentStoryJson) == jsonEncode(initialStoryJson);
  }
}
