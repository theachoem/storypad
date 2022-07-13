import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spooky/core/backups/backups_file_manager.dart';
import 'package:spooky/core/db/adapters/base/base_story_db_external_actions.dart';
import 'package:spooky/core/db/databases/base_database.dart';
import 'package:spooky/core/db/models/base/base_db_list_model.dart';
import 'package:spooky/core/db/models/story_db_model.dart';
import 'package:spooky/core/storages/local_storages/last_update_story_list_hash_storage.dart';
import 'package:spooky/utils/helpers/app_helper.dart';

StoryDbModel _constructStoryIsolate(Map<String, dynamic> json) {
  return StoryDbModel.fromJson(json);
}

abstract class BaseStoryDatabase extends BaseDatabase<StoryDbModel> {
  @override
  String get tableName => "stories";

  BaseStoryDatabase() {
    assert(adapter is BaseStoryDbExternalActions);
  }

  @override
  Future<BaseDbListModel<StoryDbModel>?> itemsTransformer(Map<String, dynamic> json) async {
    return BaseDbListModel(
      items: await buildItemsList(json),
      meta: await buildMeta(json),
      links: await buildLinks(json),
    );
  }

  @override
  Future<StoryDbModel?> objectTransformer(Map<String, dynamic> json) async {
    return compute(_constructStoryIsolate, json);
  }

  @override
  Future<void> onCRUD(StoryDbModel? object) async {
    if (object?.year == null) return;
    BackupsFileManager().clear();
    LastUpdateStoryListHashStorage().setHash(DateTime.now());
  }

  Future<Set<int>?> fetchYears() {
    BaseStoryDbExternalActions storyAdapter = adapter as BaseStoryDbExternalActions;
    return storyAdapter.fetchYears();
  }

  int getDocsCount(int? year) {
    BaseStoryDbExternalActions storyAdapter = adapter as BaseStoryDbExternalActions;
    return storyAdapter.getDocsCount(year);
  }

  @override
  Future<BaseDbListModel<StoryDbModel>?> fetchAll({Map<String, dynamic>? params}) async {
    BaseDbListModel<StoryDbModel>? result = await super.fetchAll(params: params);

    Iterable<StoryDbModel>? items = result?.items.where((story) {
      DateTime? movedToBinAt = story.movedToBinAt;
      bool shouldDelete = AppHelper.shouldDelete(movedToBinAt: movedToBinAt);
      // TODO: test to delete this
      // if (shouldDelete) deleteDocument(story);
      return !shouldDelete;
    });

    return result?.copyWith(items: items?.toList());
  }

  Future<StoryDbModel?> updatePathDate(StoryDbModel story, DateTime pathDate) async {
    StoryDbModel updatedStory = story.copyWith(
      year: pathDate.year,
      month: pathDate.month,
      day: pathDate.day,
      hour: story.displayPathDate.hour,
      minute: story.displayPathDate.minute,
    );
    StoryDbModel? result = await update(id: story.id, body: updatedStory);
    return result;
  }

  Future<StoryDbModel?> updatePathTime(StoryDbModel story, TimeOfDay time) async {
    StoryDbModel updatedStory = story.copyWith(
      hour: time.hour,
      minute: time.minute,
    );
    StoryDbModel? result = await update(id: story.id, body: updatedStory);
    return result;
  }

  Future<StoryDbModel?> deleteDocument(StoryDbModel story) async {
    return delete(
      id: story.id,
      params: {
        "type": story.type.name,
        "month": story.month,
        "year": story.year,
        "day": story.day,
      },
    );
  }
}
