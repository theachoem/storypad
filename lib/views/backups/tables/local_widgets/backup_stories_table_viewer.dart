import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

class BackupStoriesTableViewer extends StatelessWidget {
  const BackupStoriesTableViewer({
    super.key,
    required this.stories,
  });

  final List<StoryDbModel> stories;

  @override
  Widget build(BuildContext context) {
    return SpStoryList(
      viewOnly: true,
      stories: CollectionDbModel(items: stories),
      onChanged: (_) {},
      onDeleted: () {},
    );
  }
}
