import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';

class StoryListenerBuilder extends StatefulWidget {
  const StoryListenerBuilder({
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
  State<StoryListenerBuilder> createState() => _StoryListenerBuilderState();
}

class _StoryListenerBuilderState extends State<StoryListenerBuilder> {
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
