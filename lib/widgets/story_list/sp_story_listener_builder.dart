import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';

class SpStoryListenerBuilder extends StatefulWidget {
  const SpStoryListenerBuilder({
    super.key,
    required this.story,
    required this.onChanged,
    required this.builder,
    required this.onDeleted,
  });

  final StoryDbModel story;
  final void Function(StoryDbModel updatedStory) onChanged;
  final void Function() onDeleted;
  final Widget Function(BuildContext context) builder;

  @override
  State<SpStoryListenerBuilder> createState() => _SpStoryListenerBuilderState();
}

class _SpStoryListenerBuilderState extends State<SpStoryListenerBuilder> {
  late StoryDbModel story = widget.story;

  @override
  void initState() {
    StoryDbModel.db.addListener(recordId: widget.story.id, callback: listener);
    super.initState();
  }

  void listener() async {
    final reloadedStory = await StoryDbModel.db.find(story.id);

    if (reloadedStory != null) {
      story = reloadedStory;
      if (mounted) setState(() {});
      widget.onChanged(reloadedStory);
    } else {
      widget.onDeleted();
    }
  }

  @override
  void dispose() {
    StoryDbModel.db.removeListener(recordId: widget.story.id, callback: listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
