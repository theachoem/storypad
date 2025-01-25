import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/tags/edit/edit_tag_view.dart';
import 'package:storypad/views/tags/show/show_tag_view.dart';
import 'tags_view.dart';

class TagsViewModel extends BaseViewModel {
  final TagsRoute params;

  TagsViewModel({
    required this.params,
  }) {
    load();
  }

  CollectionDbModel<TagDbModel>? tags;
  Map<int, int> storiesCountByTagId = {};
  int getStoriesCount(TagDbModel tag) => storiesCountByTagId[tag.id]!;

  Future<void> load() async {
    tags = await TagDbModel.db.where();
    storiesCountByTagId.clear();

    if (tags != null) {
      for (TagDbModel tag in tags?.items ?? []) {
        storiesCountByTagId[tag.id] = await StoryDbModel.db.count(filters: {
          'tag': tag.id,
          'types': [
            PathType.archives.name,
            PathType.docs.name,
          ]
        });
      }
    }

    notifyListeners();
  }

  void viewTag(BuildContext context, TagDbModel tag) async {
    ShowTagRoute(
      storyViewOnly: params.storyViewOnly,
      tag: tag,
    ).push(context);
  }

  Future<void> deleteTag(BuildContext context, TagDbModel tag) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: "Are you sure to delete?",
      message: "You can't undo this action. Related stories will still remain",
    );

    if (result == OkCancelResult.ok) {
      await TagDbModel.db.delete(tag.id);
      await load();

      AnalyticsService.instance.logDeleteTag(
        tag: tag,
      );
    }
  }

  Future<void> editTag(BuildContext context, TagDbModel tag) async {
    final result = await EditTagRoute(tag: tag, allTags: tags?.items ?? []).push(context);

    if (result is List<String> && result.isNotEmpty) {
      TagDbModel newTag = tag.copyWith(title: result.first);
      await TagDbModel.db.set(newTag);
      await load();

      AnalyticsService.instance.logEditTag(
        tag: tag,
      );
    }
  }

  Future<void> addTag(BuildContext context) async {
    final result = await EditTagRoute(tag: null, allTags: tags?.items ?? []).push(context);

    if (result is List<String> && result.isNotEmpty) {
      TagDbModel newTag = TagDbModel.fromNow().copyWith(title: result.first);
      TagDbModel? tag = await TagDbModel.db.set(newTag);
      await load();

      if (tag == null) return;
      AnalyticsService.instance.logAddTag(
        tag: tag,
      );
    }
  }
}
