import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';

class SpStoryListWithQuery extends StatefulWidget {
  const SpStoryListWithQuery({
    super.key,
    this.viewOnly = false,
    this.filter,
    this.disableMultiEdit = false,
  });

  final SearchFilterObject? filter;
  final bool viewOnly;
  final bool disableMultiEdit;

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

    if (widget.filter?.years.length == 1 && widget.filter?.month != null && widget.filter?.day != null) {
      _throwbackDates = await StoryDbModel.db
          .where(
            filters: SearchFilterObject(
              years: {},
              excludeYears: {widget.filter!.years.first, DateTime.now().year},
              month: widget.filter?.month,
              day: widget.filter?.day,
              types: {PathType.docs, PathType.archives},
              tagId: widget.filter?.tagId,
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
  }

  @override
  void initState() {
    load(debugSource: '$runtimeType#initState');
    BackupRepository.appInstance.restoreService.addListener(_restoreServiceListener);
    super.initState();
  }

  @override
  void dispose() {
    BackupRepository.appInstance.restoreService.removeListener(_restoreServiceListener);
    super.dispose();
  }

  Future<void> _restoreServiceListener() async {
    load(debugSource: '$runtimeType#_restoreServiceListener');
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
        padding: const EdgeInsets.all(16.0),
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
        if (widget.filter?.day != null && updatedStory.day != widget.filter!.day) {
          // If filtering by day and the updated story is no longer on that day,
          // remove it from the list.
          stories = stories?.removeElement(updatedStory);
          setState(() {});
          return;
        } else if (widget.filter?.types.contains(updatedStory.type) == true) {
          stories = stories?.replaceElement(updatedStory);
        } else {
          stories = stories?.removeElement(updatedStory);
        }
        setState(() {});
      },
    );
  }
}
