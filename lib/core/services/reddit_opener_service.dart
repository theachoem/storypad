import 'package:flutter/material.dart';
import 'package:storypad/core/services/url_opener_service.dart';

class RedditOpenerService {
  /// Opens Reddit with a pre-filled post.
  /// [title] is optional. [body] is required.
  static Future<void> submitPost({
    required BuildContext context,
    required String body,
    required String? title,
  }) async {
    final encodedTitle = Uri.encodeComponent(title ?? '');
    final encodedBody = Uri.encodeComponent(body);
    UrlOpenerService.openInCustomTab(context, 'https://www.reddit.com/submit?title=$encodedTitle&text=$encodedBody');
  }
}
