import 'package:adaptive_dialog/adaptive_dialog.dart' show OkCancelResult, showOkCancelAlertDialog;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show BuildContext, ChangeNotifier;
import 'package:storypad/core/databases/models/collection_db_model.dart' show CollectionDbModel;
import 'package:storypad/core/databases/models/story_db_model.dart' show StoryDbModel;
import 'package:storypad/core/databases/models/tag_db_model.dart' show $TagDbModelCopyWith, TagDbModel;
import 'package:storypad/core/services/analytics/analytics_service.dart' show AnalyticsService;
import 'package:storypad/core/types/path_type.dart' show PathType;
import 'package:storypad/views/tags/edit/edit_tag_view.dart' show EditTagRoute;
import 'package:storypad/views/tags/show/show_tag_view.dart' show ShowTagRoute;

class TagsProvider extends ChangeNotifier {
  TagsProvider() {
    setup();
  }

  CollectionDbModel<TagDbModel>? tags = TagDbModel.db.initialTags;
  Map<int, int> storiesCountByTagId = {};

  int getStoriesCount(TagDbModel tag) => storiesCountByTagId[tag.id] ?? 0;

  Future<void> setup() async {
    storiesCountByTagId.clear();

    if (tags != null) {
      for (int i = 0; i < tags!.items.length; i++) {
        TagDbModel tag = tags!.items[i];

        if (tag.index != i) {
          tag = await TagDbModel.db.set(tag.copyWith(index: i, updatedAt: DateTime.now())) ?? tag;
          tags = tags!.replaceElement(tag);
        }
      }
    }

    for (TagDbModel tag in tags?.items ?? []) {
      storiesCountByTagId[tag.id] ??= await StoryDbModel.db.count(filters: {
        'tag': tag.id,
        'types': [PathType.docs.name]
      });
    }

    notifyListeners();
  }

  Future<void> reload() async {
    tags = await TagDbModel.db.where();
    await setup();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (tags == null) return;

    tags = tags!.reorder(oldIndex: oldIndex, newIndex: newIndex);
    notifyListeners();

    AnalyticsService.instance.logReorderTags(
      tags: tags!,
    );

    int length = tags!.items.length;
    for (int i = 0; i < length; i++) {
      final item = tags!.items[i];
      if (item.index != i) {
        await TagDbModel.db.set(item.copyWith(index: i, updatedAt: DateTime.now()));
      }
    }

    await reload();
  }

  Future<void> deleteTag(BuildContext context, TagDbModel tag) async {
    OkCancelResult result = await showOkCancelAlertDialog(
      context: context,
      title: tr('dialog.are_you_sure_to_delete_tag.title'),
      message: tr('dialog.are_you_sure_to_delete_tag.message'),
      isDestructiveAction: true,
    );

    if (result == OkCancelResult.ok) {
      await TagDbModel.db.delete(tag.id);
      await reload();

      AnalyticsService.instance.logDeleteTag(
        tag: tag,
      );
    }
  }

  Future<void> editTag(BuildContext context, TagDbModel tag) async {
    final result = await EditTagRoute(tag: tag, allTags: tags?.items ?? []).push(context);

    if (result is List<String> && result.isNotEmpty) {
      TagDbModel newTag = tag.copyWith(title: result.first, updatedAt: DateTime.now());
      await TagDbModel.db.set(newTag);
      await reload();

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
      await reload();

      if (tag == null) return;
      AnalyticsService.instance.logAddTag(
        tag: tag,
      );
    }
  }

  void viewTag({
    required BuildContext context,
    required TagDbModel tag,
    required bool storyViewOnly,
  }) async {
    ShowTagRoute(
      storyViewOnly: storyViewOnly,
      tag: tag,
    ).push(context);
  }
}
