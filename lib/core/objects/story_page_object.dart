import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/story_editor/story_pad_editor_controller.dart';

class StoryPageObject {
  final GlobalKey key;
  final StoryPadEditorController bodyController;
  final FocusNode bodyFocusNode;

  // allow changed after initialize
  late StoryPageDbModel page;

  // set from UI during interaction.
  // Use to check whether the page's top (where its title is) is visible.
  // The first page with its top visible gets the focus when moving to the edit page.
  double? titleVisibleFraction;

  int get id => page.id;

  StoryPageObject({
    required this.key,
    required this.page,
    required this.bodyController,
    required this.bodyFocusNode,
  });

  void dispose() {
    bodyController.dispose();
    bodyFocusNode.dispose();
  }
}
