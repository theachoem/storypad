import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/widgets/story_list/story_list.dart';

class StoryListWithQuery extends StatefulWidget {
  const StoryListWithQuery({
    super.key,
    this.query,
    this.viewOnly = false,
    this.filter,
  });

  final SearchFilterObject? filter;
  final String? query;
  final bool viewOnly;

  static StoryListWithQueryState? of(BuildContext context) {
    return context.findAncestorStateOfType<StoryListWithQueryState>();
  }

  @override
  State<StoryListWithQuery> createState() => StoryListWithQueryState();
}

class StoryListWithQueryState extends State<StoryListWithQuery> {
  CollectionDbModel<StoryDbModel>? stories;

  Future<void> load() async {
    stories = await StoryDbModel.db.where(
      filters: widget.filter?.toDatabaseFilter(query: widget.query) ?? {'query': widget.query},
    );

    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant StoryListWithQuery oldWidget) {
    super.didUpdateWidget(oldWidget);

    load();
  }

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StoryList(
      stories: stories,
      viewOnly: widget.viewOnly,
      onDeleted: () => load(),
      onChanged: (updatedStory) {
        if (widget.filter?.types.contains(updatedStory.type) == true) {
          stories = stories?.replaceElement(updatedStory);
        } else {
          stories = stories?.removeElement(updatedStory);
        }
        setState(() {});
      },
    );
  }
}
