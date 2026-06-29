import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/month_recap_stats_object.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/stats/stats_view.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:storypad/widgets/story_list/sp_story_tile.dart';

part 'local_widgets/story_month_header.dart';
part 'local_widgets/story_month_recap_tile.dart';

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
    this.monthlyStats,
  });

  final int index;
  final bool listHasThrowback;
  final bool listHasPinned;
  final CollectionDbModel<StoryDbModel> stories;
  final bool showYear;
  final void Function() onTap;
  final bool viewOnly;
  final BuildContext listContext;

  /// Per-month recap stats keyed by month. When null (e.g. the cross-year
  /// list), no recap tile is shown.
  final Map<int, MonthRecapStatsObject>? monthlyStats;

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
      final MonthRecapStatsObject? monthStats = monthlyStats?[story.month];

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

          // Nudge tier: only surface a monthly recap on active months so it feels
          // earned and the timeline stays clean on quiet months.
          if (monthStats != null && monthStats.shouldShowRecap) ...[
            Stack(
              children: [
                timelineDivider,
                _StoryMonthRecapTile(story: story, stats: monthStats),
              ],
            ),
          ],

          Stack(
            children: [
              timelineDivider,
              buildStoryTile(story, showMonogram, context),
            ],
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          timelineDivider,
          buildStoryTile(story, showMonogram, context),
        ],
      );
    }
  }

  Widget buildStoryTile(
    StoryDbModel story,
    bool showMonogram,
    BuildContext context,
  ) {
    return Consumer<DevicePreferencesProvider>(
      builder: (context, provider, child) {
        return SpStoryTile(
          story: story,
          preferences: provider.preferences.storyTilePreferences,
          showMonogram: showMonogram,
          viewOnly: viewOnly,
          onTap: onTap,
          listContext: listContext,
        );
      },
    );
  }
}
