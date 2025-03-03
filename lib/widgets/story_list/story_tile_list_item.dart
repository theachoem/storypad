import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/widgets/story_list/story_tile.dart';

part 'story_month_header.dart';

class StoryTileListItem extends StatelessWidget {
  const StoryTileListItem({
    super.key,
    required this.stories,
    required this.index,
    required this.showYear,
    required this.onTap,
    required this.listContext,
    this.viewOnly = false,
  });

  final int index;
  final CollectionDbModel<StoryDbModel> stories;
  final bool showYear;
  final void Function() onTap;
  final bool viewOnly;
  final BuildContext listContext;

  @override
  Widget build(BuildContext context) {
    StoryDbModel? previousStory = index - 1 >= 0 ? stories.items[index - 1] : null;
    StoryDbModel story = stories.items[index];

    bool showMonogram = previousStory == null || !previousStory.sameDayAs(story);

    if (previousStory?.month != story.month || previousStory?.year != story.year) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoryMonthHeader(index: index, context: context, story: story, showYear: showYear),
          StoryTile(
            story: story,
            showMonogram: showMonogram,
            viewOnly: viewOnly,
            onTap: onTap,
            listContext: listContext,
          ),
        ],
      );
    } else {
      return StoryTile(
        story: story,
        showMonogram: showMonogram,
        viewOnly: viewOnly,
        onTap: onTap,
        listContext: listContext,
      );
    }
  }
}
