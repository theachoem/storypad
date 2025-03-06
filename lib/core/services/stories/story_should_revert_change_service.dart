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
    StoryDbModel initialStory = params['initialStory'];
    StoryDbModel currentStory = params['currentStory'];

    Map<String, dynamic> initialStoryJson = initialStory.toJson()
      ..remove('updated_at')
      ..remove('changes');

    Map<String, dynamic> currentStoryJson = currentStory.toJson()
      ..remove('updated_at')
      ..remove('changes');

    initialStoryJson.remove('draft_content');
    initialStoryJson.remove('latest_content');

    currentStoryJson.remove('draft_content');
    currentStoryJson.remove('latest_content');

    initialStoryJson['content_to_compare'] = (initialStory.draftContent ?? initialStory.latestContent)?.toJson()
      ?..remove('id')
      ..remove('created_at')
      ..remove('plain_text')
      ..remove('metadata');

    currentStoryJson['content_to_compare'] = (currentStory.draftContent ?? currentStory.latestContent)?.toJson()
      ?..remove('id')
      ..remove('created_at')
      ..remove('plain_text')
      ..remove('metadata');

    return jsonEncode(currentStoryJson) == jsonEncode(initialStoryJson);
  }
}
