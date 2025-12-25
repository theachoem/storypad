import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/widgets/story_list/sp_story_tile.dart';

part 'local_widgets/story_month_header.dart';

class SpStoryTileListItem extends StatelessWidget {
  const SpStoryTileListItem({
    super.key,
    required this.stories,
    required this.index,
    required this.showYear,
    required this.onTap,
    required this.listContext,
    required this.listHasThrowback,
    this.listHasPinned = false,
    this.viewOnly = false,
  });

  final int index;
  final bool listHasThrowback;
  final bool listHasPinned;
  final CollectionDbModel<StoryDbModel> stories;
  final bool showYear;
  final void Function() onTap;
  final bool viewOnly;
  final BuildContext listContext;

  @override
  Widget build(BuildContext context) {
    StoryDbModel? previousStory = index - 1 >= 0 ? stories.items[index - 1] : null;
    StoryDbModel story = stories.items[index];
    StoryDbModel? nextStory = index + 1 < stories.items.length ? stories.items[index + 1] : null;
    bool showMonogram = previousStory == null || !previousStory.sameDayAs(story);

    Widget timelineDivider;

    if (nextStory != null) {
      // 1. show line all the way from header to bottom.
      timelineDivider = const Positioned(
        left: 32.0,
        top: 0,
        bottom: 0,
        child: VerticalDivider(width: 1),
      );
    } else {
      // 2. only show line from header to dot/monogram when there is no story.
      timelineDivider = const Positioned(
        left: 32.0,
        height: 16.0,
        child: VerticalDivider(width: 1),
      );
    }

    if (previousStory?.month != story.month || previousStory?.year != story.year) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // when index is 0 and there is no throwback, add extra spacing at top
          // else no padding to make UI look nicer to throwback tile on top.
          if (index == 0 && !listHasThrowback) const SizedBox(height: 12.0),

          Stack(
            children: [
              // 3. timeline divider can connect between story to story with same month,
              // when there is different month which has another header, we need to draw divider connector
              // from previous month to current.
              if (previousStory != null)
                const Positioned(
                  left: 32.0,
                  top: 0,
                  bottom: 0,
                  child: VerticalDivider(width: 1),
                ),
              _StoryMonthHeader(index: index, context: context, story: story, showYear: showYear),
            ],
          ),
          Stack(
            children: [
              timelineDivider,
              buildStoryTile(story, showMonogram),
            ],
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          timelineDivider,
          buildStoryTile(story, showMonogram),
        ],
      );
    }
  }

  Widget buildStoryTile(
    StoryDbModel story,
    bool showMonogram,
  ) {
    return SpStoryTile(
      story: story,
      showMonogram: showMonogram,
      viewOnly: viewOnly,
      onTap: onTap,
      listContext: listContext,
    );
  }
}
