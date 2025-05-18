import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';

class StoryPageObject {
  final GlobalKey key;
  final TextEditingController titleController;
  final QuillController bodyController;
  final ScrollController bodyScrollController;
  final FocusNode titleFocusNode;
  final FocusNode bodyFocusNode;

  // allow changed after initialize
  late StoryPageDbModel page;

  // set from UI during interaction.
  // Use to check whether title is visible.
  // The first title visible will be get the focused when move to edit page.
  double? titleVisibleFraction;

  double get aspectRatio => crossAxisCount / mainAxisCount;

  bool matched(double aspectRatio) => this.aspectRatio == aspectRatio;

  int get id => page.id;
  int get crossAxisCount => page.crossAxisCount;
  int get mainAxisCount => page.mainAxisCount;

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
