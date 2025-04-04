import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/services/backups/restore_backup_service.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

class SpStoryListWithQuery extends StatefulWidget {
  const SpStoryListWithQuery({
    super.key,
    this.query,
    this.viewOnly = false,
    this.filter,
  });

  final SearchFilterObject? filter;
  final String? query;
  final bool viewOnly;

  String get uniqueness => jsonEncode(filter?.toDatabaseFilter(query: query)) + viewOnly.toString();

  static SpStoryListWithQueryState? of(BuildContext context) {
    return context.findAncestorStateOfType<SpStoryListWithQueryState>();
  }

  @override
  State<SpStoryListWithQuery> createState() => SpStoryListWithQueryState();
}

class SpStoryListWithQueryState extends State<SpStoryListWithQuery> {
  CollectionDbModel<StoryDbModel>? stories;

  Future<void> load({
    required String debugSource,
  }) async {
    debugPrint("📂 Load SpStoryListWithQuery from $debugSource");

    stories = await StoryDbModel.db.where(
      filters: widget.filter?.toDatabaseFilter(query: widget.query) ?? {'query': widget.query},
    );

    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SpStoryListWithQuery oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.uniqueness != oldWidget.uniqueness) {
      load(debugSource: '$runtimeType#didUpdateWidget');
    }
  }

  @override
  void initState() {
    load(debugSource: '$runtimeType#initState');
    _listenToRestoreService();
    super.initState();
  }

  void _listenToRestoreService() {
    RestoreBackupService.instance.addListener(() async {
      load(debugSource: '$runtimeType#_listenToRestoreService');
    });
  }

  @override
  Widget build(BuildContext context) {
    return SpStoryList(
      onRefresh: () => load(debugSource: '$runtimeType#onRefresh'),
      stories: stories,
      viewOnly: widget.viewOnly,
      onDeleted: () => load(debugSource: '$runtimeType#onDeleted'),
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
