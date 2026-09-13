import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';

class SpStoryListWithQuery extends StatefulWidget {
  const SpStoryListWithQuery({
    super.key,
    this.viewOnly = false,
    this.filter,
    this.disableMultiEdit = false,
    this.watch,
  });

  final SearchFilterObject? filter;
  final bool viewOnly;
  final bool disableMultiEdit;

  /// Optional [Listenable] (e.g. a screen's view model) that, when it
  /// notifies, triggers a silent [SpStoryListWithQueryState.load] — without
  /// remounting the widget or showing the loading spinner. Lets a screen
  /// force a refresh (e.g. after a bulk action) without the full-list
  /// flash a `key` change would cause.
  final Listenable? watch;

  String get uniqueness => jsonEncode(filter?.toDatabaseFilter()) + viewOnly.toString();

  static SpStoryListWithQueryState? of(BuildContext context) {
    return context.findAncestorStateOfType<SpStoryListWithQueryState>();
  }

  @override
  State<SpStoryListWithQuery> createState() => SpStoryListWithQueryState();
}

class SpStoryListWithQueryState extends State<SpStoryListWithQuery> {
  CollectionDbModel<StoryDbModel>? stories;
  List<DateTime>? _throwbackDates;

  bool get hasThrowback => _throwbackDates?.isNotEmpty == true;

  Future<void> load({
    required String debugSource,
  }) async {
    debugPrint("📂 Load SpStoryListWithQuery from $debugSource");

    stories = await StoryDbModel.db.where(
      filters: widget.filter?.toDatabaseFilter(),
    );
    StoryContentEmbedExtractor.preloadAssetAspectRatios(stories?.items ?? []);

    if (widget.filter?.years.length == 1 && widget.filter?.month != null && widget.filter?.day != null) {
      _throwbackDates = await StoryDbModel.db
          .where(
            filters: SearchFilterObject(
              years: {},
              excludeYears: {widget.filter!.years.first, DateTime.now().year},
              month: widget.filter?.month,
              day: widget.filter?.day,
              types: {PathType.docs, PathType.archives},
              tagIds: widget.filter?.tagIds ?? {},
              assetId: null,
            ).toDatabaseFilter(),
          )
          .then((e) => e?.items.map((e) => e.displayPathDate).toSet().toList());
    }

    if (mounted) setState(() {});

    if (!widget.disableMultiEdit && mounted) {
      try {
        SpStoryListMultiEditWrapper.of(context).stories.clear();
        SpStoryListMultiEditWrapper.of(context).stories.addAll(stories?.items.map((e) => e.id) ?? {});
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  @override
  void didUpdateWidget(covariant SpStoryListWithQuery oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.uniqueness != oldWidget.uniqueness) {
      stories = null;
      load(debugSource: '$runtimeType#didUpdateWidget');
    }

    if (widget.watch != oldWidget.watch) {
      oldWidget.watch?.removeListener(_watchListener);
      widget.watch?.addListener(_watchListener);
    }
  }

  @override
  void initState() {
    load(debugSource: '$runtimeType#initState');
    BackupProvider.repoInstance.restoreService.addListener(_restoreServiceListener);
    widget.watch?.addListener(_watchListener);
    super.initState();
  }

  @override
  void dispose() {
    BackupProvider.repoInstance.restoreService.removeListener(_restoreServiceListener);
    widget.watch?.removeListener(_watchListener);
    super.dispose();
  }

  Future<void> _restoreServiceListener() async {
    load(debugSource: '$runtimeType#_restoreServiceListener');
  }

  Future<void> _watchListener() async {
    load(debugSource: '$runtimeType#watch');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.disableMultiEdit) {
      return SpStoryListMultiEditWrapper(
        disabled: true,
        builder: (context) {
          return buildFadeInList();
        },
      );
    } else {
      return buildFadeInList();
    }
  }

  Widget buildFadeInList() {
    if (stories?.items == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (stories!.items.isEmpty && !hasThrowback) {
      return Padding(
        padding: const EdgeInsets.all(16.0).add(
          EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
        ),
        child: Text(
          tr('general.no_story_yet'),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: .center,
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey(widget.uniqueness),
      child: SpFadeIn.fromBottom(
        child: buildList(),
      ),
    );
  }

  SpStoryList buildList() {
    return SpStoryList(
      onRefresh: () => load(debugSource: '$runtimeType#onRefresh'),
      stories: stories,
      throwbackDates: _throwbackDates,
      viewOnly: widget.viewOnly,
      onDeleted: () => load(debugSource: '$runtimeType#onDeleted'),
      onChanged: (updatedStory) {
        final filter = widget.filter;
        final dayMismatch = filter?.day != null && updatedStory.day != filter!.day;
        final typeMismatch = filter?.types.isNotEmpty == true && !filter!.types.contains(updatedStory.type);
        final starredMismatch = filter?.starred != null && updatedStory.starred != filter!.starred;
        final pinnedMismatch = filter?.pinned != null && updatedStory.pinned != filter!.pinned;

        if (dayMismatch || typeMismatch || starredMismatch || pinnedMismatch) {
          // The updated story no longer matches this list's filter (e.g. it
          // was archived/put back/un-starred) — remove it instead of leaving
          // a stale entry behind until the next manual refresh.
          stories = stories?.removeElement(updatedStory);
        } else {
          stories = stories?.replaceElement(updatedStory);
        }
        setState(() {});
      },
    );
  }
}
