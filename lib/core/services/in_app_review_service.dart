import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:storypad/core/storages/story_write_count_storage.dart';

class InAppReviewService {
  static const List<int> _thresholds = [3, 10, 25];
  static final StoryWriteCountStorage _storage = StoryWriteCountStorage();

  static Future<void> maybeRequest() async {
    final count = await _storage.increment();
    if (_thresholds.contains(count)) {
      await request();
    }
  }

  static Future<void> request() async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      try {
        await inAppReview.requestReview();
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }
}
