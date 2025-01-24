import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/views/stories/changes/show/show_change_view.dart';
import 'package:storypad/views/stories/show/show_story_view.dart';
import 'package:storypad/widgets/story_list/story_list_timeline_verticle_divider.dart';
import 'package:storypad/widgets/story_list/story_listener_builder.dart';
import 'package:storypad/widgets/story_list/story_tile_list_item.dart';

class StoryList extends StatelessWidget {
  final CollectionDbModel<StoryDbModel>? stories;
  final void Function(StoryDbModel) onChanged;
  final void Function() onDeleted;
  final bool viewOnly;

  const StoryList({
    super.key,
    this.stories,
    required this.onChanged,
    required this.onDeleted,
    this.viewOnly = false,
  });

  static StoryListWithQuery withQuery({
    int? year,
    int? tagId,
    List<PathType>? types,
    String? query,
    bool viewOnly = false,
  }) {
    return StoryListWithQuery(
      year: year,
      tagId: tagId,
      types: types,
      query: query,
      viewOnly: viewOnly,
    );
  }

  Future<void> putBack(StoryDbModel story, BuildContext context) async {
    await story.putBack();
    if (context.mounted) context.read<HomeViewModel>().load(debugSource: '$runtimeType#putBack');
  }

  @override
  Widget build(BuildContext context) {
    if (stories?.items == null) return const Center(child: CircularProgressIndicator.adaptive());

    return Stack(
      children: [
        const StoryListTimelineVerticleDivider(),
        buildList(context),
      ],
    );
  }

  Widget buildList(BuildContext listContext) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16.0)
          .copyWith(left: MediaQuery.of(listContext).padding.left, right: MediaQuery.of(listContext).padding.right),
      itemCount: stories?.items.length ?? 0,
      itemBuilder: (context, index) {
        final story = stories!.items[index];
        return StoryListenerBuilder(
          story: story,
          key: ValueKey(story.id),
          onChanged: onChanged,
          // onDeleted only happen when reloaded story is null which not frequently happen. We just reload in this case.
          onDeleted: onDeleted,
          builder: (context) {
            return StoryTileListItem(
              showYear: true,
              stories: stories!,
              index: index,
              viewOnly: viewOnly,
              listContext: listContext,
              onTap: () {
                if (viewOnly) {
                  ShowChangeRoute(content: story.latestChange!).push(context);
                } else {
                  ShowStoryRoute(id: story.id, story: story).push(context);
                }
              },
            );
          },
        );
      },
    );
  }
}

class StoryListWithQuery extends StatefulWidget {
  const StoryListWithQuery({
    super.key,
    this.year,
    this.tagId,
    this.types,
    this.query,
    this.viewOnly = false,
  });

  final int? year;
  final int? tagId;
  final List<PathType>? types;
  final String? query;
  final bool viewOnly;

  @override
  State<StoryListWithQuery> createState() => _StoryListWithQueryState();
}

class _StoryListWithQueryState extends State<StoryListWithQuery> {
  CollectionDbModel<StoryDbModel>? stories;

  Future<void> load() async {
    stories = await StoryDbModel.db.where(filters: {
      'year': widget.year,
      'tag': widget.tagId,
      'types': widget.types?.map((t) => t.name).toList(),
      'query': widget.query,
    });

    setState(() {});
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
        if (widget.types?.contains(updatedStory.type) == true) {
          stories = stories?.replaceElement(updatedStory);
        } else {
          stories = stories?.removeElement(updatedStory);
        }
        setState(() {});
      },
    );
  }
}
