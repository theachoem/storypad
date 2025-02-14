import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';

class StoryListMultiEditWrapperState extends ChangeNotifier {
  bool editing = false;
  Set<int> selectedStories = {};

  void toggleSelection(StoryDbModel story) {
    if (selectedStories.contains(story.id)) {
      selectedStories.remove(story.id);
    } else {
      selectedStories.add(story.id);
    }
    notifyListeners();
  }

  void turnOnEditing({
    int? initialId,
  }) {
    editing = true;
    selectedStories.clear();
    if (initialId != null) selectedStories.add(initialId);
    notifyListeners();
  }

  void turnOffEditing({
    int? initialId,
  }) {
    editing = false;
    selectedStories.clear();
    notifyListeners();
  }
}

class StoryListMultiEditWrapper extends StatelessWidget {
  const StoryListMultiEditWrapper({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context) builder;

  static StoryListMultiEditWrapperState of(BuildContext context) {
    return context.read<StoryListMultiEditWrapperState>();
  }

  static tryListen({
    required BuildContext context,
    required Widget Function(BuildContext context, StoryListMultiEditWrapperState? state) builder,
  }) {
    bool hasProvider = false;

    try {
      context.read<StoryListMultiEditWrapperState>();
      hasProvider = true;
    } catch (e) {
      hasProvider = false;
    }

    if (!hasProvider) {
      return builder(context, null);
    }

    return Consumer<StoryListMultiEditWrapperState>(
      builder: (context, state, child) {
        return builder(context, state);
      },
    );
  }

  static listen({
    required BuildContext context,
    required Widget Function(BuildContext context, StoryListMultiEditWrapperState state) builder,
  }) {
    return Consumer<StoryListMultiEditWrapperState>(
      builder: (context, state, child) {
        return builder(context, state);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableProvider(
      create: (context) => StoryListMultiEditWrapperState(),
      builder: (context, child) => builder(context),
    );
  }
}
