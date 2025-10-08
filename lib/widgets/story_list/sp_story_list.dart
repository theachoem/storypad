import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';
import 'package:storypad/widgets/sp_throwback_tile.dart';
import 'package:storypad/widgets/story_list/sp_story_list_timeline_verticle_divider.dart';
import 'package:storypad/widgets/story_list/sp_story_list_with_query.dart';
import 'package:storypad/widgets/story_list/sp_story_listener_builder.dart';
import 'package:storypad/widgets/story_list/sp_story_tile_list_item.dart';

class SpStoryList extends StatelessWidget {
  final CollectionDbModel<StoryDbModel>? stories;
  final List<DateTime>? throwbackDates;
  final void Function(StoryDbModel) onChanged;
  final void Function() onDeleted;
  final bool viewOnly;
  final Future<void> Function()? onRefresh;

  bool get hasThrowback => throwbackDates?.isNotEmpty == true;

  const SpStoryList({
    super.key,
    this.stories,
    this.throwbackDates,
    required this.onChanged,
    required this.onDeleted,
    this.onRefresh,
    this.viewOnly = false,
  });

  static SpStoryListWithQuery withQuery({
    Key? key,
    SearchFilterObject? filter,
    String? query,
    bool viewOnly = false,
    bool disableMultiEdit = false,
  }) {
    return SpStoryListWithQuery(
      key: key,
      filter: filter,
      query: query,
      viewOnly: viewOnly,
      disableMultiEdit: disableMultiEdit,
    );
  }

  Future<void> putBack(StoryDbModel story, BuildContext context) async {
    await story.putBack();
    HomeView.reload(debugSource: '$runtimeType#putBack');
  }

  @override
  Widget build(BuildContext context) {
    if (stories?.items == null) return const Center(child: CircularProgressIndicator.adaptive());

    return Stack(
      children: [
        const SpSpStoryListTimelineVerticleDivider(),
        if (onRefresh != null) ...[
          RefreshIndicator.adaptive(
            onRefresh: onRefresh!,
            child: buildList(context),
          ),
        ] else ...[
          buildList(context),
        ],
      ],
    );
  }

  Widget buildList(BuildContext listContext) {
    int itemsCount = stories?.items.length ?? 0;
    if (hasThrowback) itemsCount += 1;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: 16.0,
        left: MediaQuery.of(listContext).padding.left,
        right: MediaQuery.of(listContext).padding.right,
        bottom: MediaQuery.of(listContext).padding.bottom + 16.0,
      ),
      itemCount: itemsCount,
      itemBuilder: (context, itemIndex) {
        if (hasThrowback && itemIndex == 0) {
          return SpThrowbackTile(
            throwbackDates: throwbackDates,
          );
        }

        int storyIndex = itemIndex;
        if (hasThrowback) storyIndex = itemIndex - 1;

        StoryDbModel story = stories!.items[storyIndex];

        return SpStoryListenerBuilder(
          story: story,
          key: ValueKey(story.id),
          onChanged: onChanged,
          // onDeleted only happen when reloaded story is null which not frequently happen. We just reload in this case.
          onDeleted: onDeleted,
          builder: (context) {
            return SpStoryTileListItem(
              showYear: true,
              stories: stories!,
              index: storyIndex,
              viewOnly: viewOnly,
              listContext: listContext,
              onTap: () {
                if (viewOnly) {
                  ShowChangeRoute(content: story.latestContent!, preferences: story.preferences).push(context);
                } else {
                  ShowStoryRoute(id: story.id, story: story).push(context, rootNavigator: true);
                }
              },
            );
          },
        );
      },
    );
  }
}
