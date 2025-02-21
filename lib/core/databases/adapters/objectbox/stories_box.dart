import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/story_db_constructor_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/objectbox.g.dart';

class StoriesBox extends BaseBox<StoryObjectBox, StoryDbModel> {
  @override
  String get tableName => "stories";

  @override
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) async {
    Condition<StoryObjectBox>? conditions = StoryObjectBox_.id.notNull();

    if (fromThisDeviceOnly == true) {
      conditions.and(StoryObjectBox_.lastSavedDeviceId.equals(kDeviceInfo.id));
    }

    Query<StoryObjectBox> query =
        box.query(conditions).order(StoryObjectBox_.updatedAt, flags: Order.descending).build();
    StoryObjectBox? object = await query.findFirstAsync();
    return object?.updatedAt;
  }

  Future<Map<int, int>> getStoryCountsByYear({
    Map<String, dynamic>? filters,
  }) async {
    List<StoryObjectBox>? stories = await buildQuery(filters: filters).build().findAsync();

    Map<int, int>? storyCountsByYear = stories.fold<Map<int, int>>({}, (counts, story) {
      counts[story.year] = (counts[story.year] ?? 0) + 1;
      return counts;
    });

    storyCountsByYear[DateTime.now().year] ??= 0;

    return storyCountsByYear;
  }

  Future<Map<PathType, int>> getStoryCountsByType({
    Map<String, dynamic>? filters,
  }) async {
    Map<PathType, int> storyCountsByType = {};

    for (PathType type in PathType.values) {
      storyCountsByType[type] = buildQuery(filters: {
        ...filters ?? {},
        'type': type.name,
      }).build().count();
    }

    return storyCountsByType;
  }

  @override
  Future<StoryDbModel?> set(
    StoryDbModel record, {
    bool runCallbacks = true,
  }) async {
    StoryDbModel? saved = await super.set(record, runCallbacks: runCallbacks);
    debugPrint("🚧 StoryBox#set: ${saved?.rawChanges?.length}");
    return saved;
  }

  @override
  QueryBuilder<StoryObjectBox> buildQuery({Map<String, dynamic>? filters}) {
    String? query = filters?["query"];
    String? type = filters?["type"];
    List<String>? types = filters?["types"];
    int? year = filters?["year"];
    List<int>? years = filters?["years"];
    int? month = filters?["month"];
    int? day = filters?["day"];
    int? tag = filters?["tag"];
    int? asset = filters?["asset"];
    bool? starred = filters?["starred"];
    int? order = filters?["order"];
    bool priority = filters?["priority"] == true;
    List<int>? selectedYears = filters?["selected_years"];
    List<int>? yearsRange = filters?["years_range"];

    Condition<StoryObjectBox>? conditions =
        StoryObjectBox_.id.notNull().and(StoryObjectBox_.permanentlyDeletedAt.isNull());

    if (tag != null) conditions = conditions.and(StoryObjectBox_.tags.containsElement(tag.toString()));
    if (asset != null) conditions = conditions.and(StoryObjectBox_.assets.equals(asset));
    if (starred == true) conditions = conditions.and(StoryObjectBox_.starred.equals(true));
    if (type != null) conditions = conditions.and(StoryObjectBox_.type.equals(type));
    if (types != null) conditions = conditions.and(StoryObjectBox_.type.oneOf(types));
    if (year != null) conditions = conditions.and(StoryObjectBox_.year.equals(year));
    if (years != null) conditions = conditions.and(StoryObjectBox_.year.oneOf(years));
    if (month != null) conditions = conditions.and(StoryObjectBox_.month.equals(month));
    if (day != null) conditions = conditions.and(StoryObjectBox_.day.equals(day));

    if (query != null) {
      conditions = conditions.and(
        StoryObjectBox_.metadata.contains(
          query,
          caseSensitive: false,
        ),
      );
    }

    if (yearsRange != null && yearsRange.length == 2) {
      yearsRange.sort();
      conditions = conditions.and(
        StoryObjectBox_.year.between(
          yearsRange[0],
          yearsRange[1],
        ),
      );
    } else if (selectedYears != null) {
      conditions = conditions.and(StoryObjectBox_.year.oneOf(selectedYears));
    }

    QueryBuilder<StoryObjectBox> queryBuilder = box.query(conditions);
    if (priority) queryBuilder.order(StoryObjectBox_.starred, flags: Order.descending);

    queryBuilder
      ..order(StoryObjectBox_.year, flags: order ?? Order.descending)
      ..order(StoryObjectBox_.month, flags: order ?? Order.descending)
      ..order(StoryObjectBox_.day, flags: order ?? Order.descending)
      ..order(StoryObjectBox_.hour, flags: order ?? Order.descending)
      ..order(StoryObjectBox_.minute, flags: order ?? Order.descending);

    return queryBuilder;
  }

  @override
  StoryDbModel modelFromJson(Map<String, dynamic> json) {
    return StoryDbModel.fromJson(json);
  }

  @override
  Future<List<StoryDbModel>> objectsToModels(
    List<StoryObjectBox> objects, [
    Map<String, dynamic>? options,
  ]) {
    return compute(_objectsToModels, {
      'objects': objects,
      'options': options,
    });
  }

  @override
  Future<List<StoryObjectBox>> modelsToObjects(List<StoryDbModel> models, [Map<String, dynamic>? options]) {
    return compute(_modelsToObjects, {
      'models': models,
      'options': options,
    });
  }

  @override
  Future<StoryObjectBox> modelToObject(
    StoryDbModel model, [
    Map<String, dynamic>? options,
  ]) {
    return compute(_modelToObject, {
      'model': model,
      'options': options,
    });
  }

  @override
  Future<StoryDbModel> objectToModel(
    StoryObjectBox object, [
    Map<String, dynamic>? options,
  ]) {
    return compute(_objectToModel, {
      'object': object,
      'options': options,
    });
  }

  static StoryDbModel _objectToModel(Map<String, dynamic> map) {
    StoryObjectBox object = map['object'];
    Map<String, dynamic>? options = map['options'];

    Iterable<PathType> types = PathType.values.where((e) => e.name == object.type);

    return StoryDbModel(
      type: types.isNotEmpty ? types.first : PathType.docs,
      id: object.id,
      starred: object.starred,
      feeling: object.feeling,
      year: object.year,
      month: object.month,
      day: object.day,
      hour: object.hour ?? object.createdAt.hour,
      minute: object.minute ?? object.createdAt.minute,
      second: object.second ?? object.createdAt.second,
      updatedAt: object.updatedAt,
      createdAt: object.createdAt,
      tags: object.tags,
      assets: object.assets,
      preferences: StoryDbConstructorService.decodePreferences(object),
      rawChanges: object.changes,
      movedToBinAt: object.movedToBinAt,
      lastSavedDeviceId: object.lastSavedDeviceId,
      latestChange:
          object.changes.isNotEmpty ? StoryDbConstructorService.rawChangesToChanges([object.changes.last]).first : null,
      allChanges:
          options?['all_changes'] == true ? StoryDbConstructorService.rawChangesToChanges(object.changes) : null,
    );
  }

  static List<StoryDbModel> _objectsToModels(Map<String, dynamic> map) {
    List<StoryObjectBox> objects = map['objects'];
    Map<String, dynamic>? options = map['options'];

    List<StoryDbModel> docs = [];
    for (StoryObjectBox object in objects) {
      StoryDbModel json = _objectToModel({
        'object': object,
        'options': options,
      });

      docs.add(json);
    }

    return docs;
  }

  static List<StoryObjectBox> _modelsToObjects(Map<String, dynamic> map) {
    List<StoryDbModel> models = map['models'];
    Map<String, dynamic>? options = map['options'];

    List<StoryObjectBox> docs = [];
    for (StoryDbModel model in models) {
      StoryObjectBox json = _modelToObject({
        'model': model,
        'options': options,
      });

      docs.add(json);
    }

    return docs;
  }

  static StoryObjectBox _modelToObject(Map<String, dynamic> map) {
    StoryDbModel story = map['model'];

    return StoryObjectBox(
      id: story.id,
      version: story.version,
      type: story.type.name,
      year: story.year,
      month: story.month,
      day: story.day,
      hour: story.hour ?? story.createdAt.hour,
      minute: story.minute ?? story.createdAt.minute,
      second: story.second ?? story.createdAt.second,
      tags: story.tags?.map((e) => e.toString()).toList(),
      assets: story.assets?.toSet().toList(),
      starred: story.starred,
      feeling: story.feeling,
      showDayCount: null,
      createdAt: story.createdAt,
      updatedAt: story.updatedAt,
      movedToBinAt: story.movedToBinAt,
      metadata: story.latestChange?.safeMetadata,
      changes: StoryDbConstructorService.changesToRawChanges(story),
      permanentlyDeletedAt: null,
      preferences: story.preferences != null ? jsonEncode(story.preferences?.toJson()) : null,
    );
  }
}
