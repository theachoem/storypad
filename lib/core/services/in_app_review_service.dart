import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

class InAppReviewService {
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
