import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/objectbox.g.dart';

part 'helpers/stories_box_transformer.dart';

class StoriesBox extends BaseBox<StoryObjectBox, StoryDbModel> {
  @override
  String get tableName => "stories";

  Future<void> migrateDataToV2() async {
    final conditions = StoryObjectBox_.id
        .notNull()
        .and(StoryObjectBox_.permanentlyDeletedAt.isNull())
        .and(StoryObjectBox_.version.equals(1));

    final queryBuilder = box.query(conditions);
    final boxes = await queryBuilder.build().findAsync();

    int count = 0;

    for (var storyBox in boxes) {
      if (storyBox.version == 1) {
        storyBox.latestContent = storyBox.changes.last;
        storyBox.changes = [];
        storyBox.version = 2;
        await box.putAsync(storyBox);
      }
    }

    debugPrint('🤾‍♀️ Migrated Stories: $count');
  }

  @override
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) async {
    debugPrint("Triggering $tableName#getLastUpdatedAt 🍎");

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
    debugPrint("Triggering $tableName#getStoryCountsByYear 🍎");

    List<StoryObjectBox>? stories = await buildQuery(filters: filters).build().findAsync();

    Map<int, int>? storyCountsByYear = stories.fold<Map<int, int>>({}, (counts, story) {
      counts[story.year] = (counts[story.year] ?? 0) + 1;
      return counts;
    });

    storyCountsByYear[DateTime.now().year] ??= 0;
    return SplayTreeMap<int, int>.from(storyCountsByYear, (a, b) => b.compareTo(a));
  }

  Future<Map<PathType, int>> getStoryCountsByType({
    Map<String, dynamic>? filters,
  }) async {
    debugPrint("Triggering $tableName#getStoryCountsByType 🍎");

    Map<PathType, int> storyCountsByType = {};

    for (PathType type in PathType.values) {
      storyCountsByType[type] = buildQuery(filters: {
        ...filters ?? {},
        'type': type.name,
      }).build().count();
    }

    return storyCountsByType;
  }

  Map<int, String?> getStoryFeelingByMonth({
    required int month,
    required int year,
    int? tagId,
  }) {
    debugPrint("Triggering $tableName#getStoryFeelingByMonth 🍎");

    Map<int, String?> storyFeelingByMonth = {};

    Map<String, Object> filters = {
      'year': year,
      'month': month,
      'type': PathType.docs.name,
    };

    if (tagId != null) filters['tag'] = tagId;
    final result = buildQuery(filters: filters).build().find();

    for (final story in result) {
      if (story.feeling != null) {
        storyFeelingByMonth[story.day] = story.feeling;
      } else if (story.feeling == null && storyFeelingByMonth[story.day] == null) {
        storyFeelingByMonth[story.day] = 'exist_but_not_set';
      }
    }

    return storyFeelingByMonth;
  }

  @override
  Future<StoryDbModel?> set(
    StoryDbModel record, {
    bool runCallbacks = true,
  }) async {
    StoryDbModel? saved = await super.set(record, runCallbacks: runCallbacks);
    debugPrint("🚧 StoryBox#set: latest ${saved?.latestContent?.id}, draft: ${saved?.draftContent?.id}");
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
    if (starred != null) conditions = conditions.and(StoryObjectBox_.starred.equals(starred));
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
    /// Migrate to v2, mostly from backup file. For DB level check: [StoriesBox#migrateDataToV2]
    if (json['version'] == 1) {
      final changes = json['changes'];

      if (changes is List) {
        final latestContent = changes.last;

        if (latestContent is Map<String, dynamic>) {
          json['latest_content'] = latestContent;
          json['version'] = 2;

          // model no longer has changes field.
          json.remove('changes');
        }
      }
    }

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
}
