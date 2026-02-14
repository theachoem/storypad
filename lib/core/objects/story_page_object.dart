import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/rich_text/rich_text.dart';

class StoryPageObject {
  final GlobalKey key;
  final TextEditingController titleController;
  final RichTextController bodyController;
  final ScrollController bodyScrollController;
  final FocusNode titleFocusNode;
  final FocusNode bodyFocusNode;

  // allow changed after initialize
  late StoryPageDbModel page;

  // set from UI during interaction.
  // Use to check whether title is visible.
  // The first title visible will be get the focused when move to edit page.
  double? titleVisibleFraction;

  int get id => page.id;

  StoryPageObject({
    required this.key,
    required this.page,
    required this.titleController,
    required this.bodyController,
    required this.bodyScrollController,
    required this.titleFocusNode,
    required this.bodyFocusNode,
  });

  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    bodyScrollController.dispose();
    titleFocusNode.dispose();
    bodyFocusNode.dispose();
  }
}
