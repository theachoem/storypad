import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/adapters/objectbox/events_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/helpers/story_content_helper.dart';
import 'package:storypad/core/databases/adapters/objectbox/tags_box.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/sp_latlng_bounds.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/objectbox.g.dart';

part 'helpers/stories_box_transformer.dart';

class MapStoryObject {
  final int id;
  final List<int>? assets;
  final SpLatLng location;
  final DateTime storyDate;
  final String? placeName;

  MapStoryObject({
    required this.id,
    required this.assets,
    required this.location,
    required this.storyDate,
    required this.placeName,
  });
}

class StoriesBox extends BaseBox<StoryObjectBox, StoryDbModel> {
  @override
  String get tableName => "stories";

  @override
  QueryIntegerProperty<StoryObjectBox> get idProperty => StoryObjectBox_.id;

  @override
  QueryStringProperty<StoryObjectBox> get lastSavedDeviceIdProperty => StoryObjectBox_.lastSavedDeviceId;

  @override
  QueryDateProperty<StoryObjectBox> get permanentlyDeletedAtProperty => StoryObjectBox_.permanentlyDeletedAt;

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

    AppLogger.info('🤾‍♀️ Migrated Stories: $count');
  }

  Future<void> migrateFeelingToTags() async {
    final legacyFeelingToEmojiMap = {
      // FeelingGroup.joy
      'positive_feelings': "😊",
      'smiling_halo': "😇",
      'cheerfulness': "😀",
      'beaming': "😄",
      'smiling_broadly': "😁",
      'laughter': "😆",
      'really_funny': "😂",
      'winking': "😜",
      'in_love': "😍",
      'lovely': "🥰",
      'blowing': "😘",
      'cuteness': "😛",
      'annoy_someone': "😝",
      'savoring_food': "😋",
      'crazy': "😉",
      'zany': "🤪",
      'something_cool': "😎",
      'excited': "🤩",
      'getting_rich': "🤑",

      // FeelingGroup.sadness
      'crying': "😢",
      'loudly_crying': "😭",
      'downcast': "😞",
      'disappointed': "😔",
      'tired': "😫",

      // FeelingGroup.fear
      'nervousness': "😬",
      'fearful': "😨",
      'worry': "😖",
      'grinning_sweat': "😅",

      // FeelingGroup.anger
      'serious': "🤬",
      'pouting': "😡",
      'mistrust': "🤨",

      // FeelingGroup.neutral
      'neutral': "😐",
      'slightly_smiling': "🙂",
      'confused': "😕",
      'expressionless': "😑",
      'head_bandage': "🤕",
      'medical_mask': "😷",
      'speechlessness': "😶",
      'flushed': "😳",
      'rolling_eyes': "🙄",

      // FeelingGroup.other
      'nerd': "🤓",
      'monocle': "🧐",
      'sleeping': "😴",
      'dizzy': "😵",
      'suggestive_smile': "😏",
      'wow': "😮",
      'devil': "😈",
      'drooling': "🤤",
      'vomiting': "🤮",
      'nauseated': "🤢",
    };

    final conditions = StoryObjectBox_.id
        .notNull()
        .and(StoryObjectBox_.permanentlyDeletedAt.isNull())
        .and(StoryObjectBox_.feeling.notNull());

    final queryBuilder = box.query(conditions);
    final query = queryBuilder.build();

    if (query.count() == 0) {
      AppLogger.info('No stories to migrate from feeling to tags');
      return;
    }

    final boxes = await query.findAsync();
    List<StoryObjectBox> stories = [];
    Map<String, TagDbModel> tags = {};

    int migratedCount = 0;

    for (var story in boxes) {
      final emoji = legacyFeelingToEmojiMap[story.feeling];

      if (emoji != null) {
        final tag = TagDbModel.emoji(emoji, categoryId: TagCategoryDbModel.feeling().id);
        story.tags = {...?story.tags, tag.id.toString()}.toList();
        tags[tag.id.toString()] = tag;
        migratedCount++;
      }

      story.feeling = null;
      stories.add(story);
    }

    await box.putManyAsync(stories);
    await TagDbModel.db.setAll(tags.values.toList());

    AppLogger.info('🤾‍♀️ Migrated Feeling to Tags: $migratedCount');
  }

  /// Clear search index for related stories so it get picked up to reindex when open search view.
  Future<void> clearSearchIndex({required Map<String, int> filters}) async {
    return buildQuery(filters: filters).build().findAsync().then((boxes) async {
      await box.putManyAsync(boxes.map((e) => e..searchMetadata = null).toList());
    });
  }

  /// Regenerates searchMetadata for stories that don't have it (legacy data from older versions).
  ///
  /// Background:
  /// - [searchMetadata] should never be null; it's a concatenated string of all page titles and bodies
  ///   generated in DB level here in [_generateSearchMetadata] when stories are saved.
  /// - Older app versions may have stories missing this field, causing search to not find them.
  ///
  /// Call this only on the search view (lazy-load pattern) when needed to search text,
  Future<void> reindexSearchMetadata() async {
    final tagById = await TagsBox().box
        .query(TagObjectBox_.id.notNull().and(TagObjectBox_.permanentlyDeletedAt.isNull()))
        .build()
        .findAsync()
        .then((e) => {for (var item in e) item.id: item.title});

    final conditions = StoryObjectBox_.id
        .notNull()
        .and(StoryObjectBox_.permanentlyDeletedAt.isNull())
        .and(StoryObjectBox_.searchMetadata.isNull());

    final queryBuilder = box.query(conditions);
    final boxes = await queryBuilder.build().findAsync();

    int count = 0;
    int failed = 0;

    const batchSize = 50;

    for (int i = 0; i < boxes.length; i += batchSize) {
      final batch = boxes.sublist(i, math.min(i + batchSize, boxes.length));

      final toUpdate = await Isolate.run(() {
        final toUpdate = <StoryObjectBox>[];

        for (var storyBox in batch) {
          try {
            final contentStr = storyBox.draftContent ?? storyBox.latestContent;
            final content = StoryContentHelper.stringToContent(contentStr!);
            final updatedMetadata = _generateSearchMetadata(
              storyBox.placeName,
              DateTime(storyBox.year, storyBox.month, storyBox.day),
              content,
              storyBox.tags?.map((id) => tagById[int.tryParse(id) ?? -1]).whereType<String>().toList(),
            );
            storyBox.searchMetadata = updatedMetadata;
            toUpdate.add(storyBox);
            count++;
          } catch (e, stackTrace) {
            AppLogger.error('Failed to reindex story ${storyBox.id}', error: e, stackTrace: stackTrace);
            failed++;
          }
        }

        return toUpdate;
      });

      if (toUpdate.isNotEmpty) {
        await box.putManyAsync(toUpdate);
      }
    }

    AppLogger.info('🔍 Reindexed Stories: $count (Failed: $failed)');
  }

  Future<List<MapStoryObject>> getStoriesWithLocation({
    SpLatLngBounds? bounds,
    int? limit,
  }) async {
    Condition<StoryObjectBox> conditions = _storiesWithLocationConditions();

    if (bounds != null) {
      conditions = conditions
          .and(StoryObjectBox_.latitude.between(bounds.south, bounds.north))
          .and(StoryObjectBox_.longitude.between(bounds.west, bounds.east));
    }

    final queryBuilder = box.query(conditions);
    final query = queryBuilder.build();
    if (limit != null) query.limit = limit;

    final result = await query.findAsync();

    List<MapStoryObject> storiesWithLocation = [];
    for (var story in result) {
      storiesWithLocation.add(
        MapStoryObject(
          id: story.id,
          assets: story.assets?.isNotEmpty == true ? story.assets : null,
          location: SpLatLng(story.latitude!, story.longitude!),
          placeName: story.placeName,
          storyDate: DateTime(
            story.year,
            story.month,
            story.day,
            story.hour ?? 0,
            story.minute ?? 0,
            story.second ?? 0,
          ),
        ),
      );
    }

    return storiesWithLocation;
  }

  Future<List<MapStoryObject>> getRecentStoriesWithLocation({int limit = 50}) async {
    final queryBuilder = box.query(_storiesWithLocationConditions())
      ..order(StoryObjectBox_.year, flags: Order.descending)
      ..order(StoryObjectBox_.month, flags: Order.descending)
      ..order(StoryObjectBox_.day, flags: Order.descending)
      ..order(StoryObjectBox_.hour, flags: Order.descending)
      ..order(StoryObjectBox_.minute, flags: Order.descending);

    final query = queryBuilder.build();
    query.limit = limit;

    final result = await query.findAsync();
    return result.map(_objectToMapStoryObject).toList();
  }

  Condition<StoryObjectBox> _storiesWithLocationConditions() {
    return StoryObjectBox_.id
        .notNull()
        .and(StoryObjectBox_.permanentlyDeletedAt.isNull())
        .and(StoryObjectBox_.latitude.notNull())
        .and(StoryObjectBox_.longitude.notNull())
        .and(StoryObjectBox_.place.notNull());
  }

  MapStoryObject _objectToMapStoryObject(StoryObjectBox story) {
    return MapStoryObject(
      id: story.id,
      assets: story.assets?.isNotEmpty == true ? story.assets : null,
      location: SpLatLng(story.latitude!, story.longitude!),
      placeName: story.placeName,
      storyDate: DateTime(
        story.year,
        story.month,
        story.day,
        story.hour ?? 0,
        story.minute ?? 0,
        story.second ?? 0,
      ),
    );
  }

  Future<Map<int, int>> getStoryCountsByYear({
    Map<String, dynamic>? filters,
  }) async {
    AppLogger.info("Triggering $tableName#getStoryCountsByYear 🍎");

    Map<String, dynamic> filtersWithoutYear = {...filters ?? {}}
      ..removeWhere((key, value) => key == 'year' || key == 'years');

    List<int> years = (buildQuery(
      filters: filtersWithoutYear,
    ).build().property(StoryObjectBox_.year)..distinct = true).find();

    Map<int, int> storyCountsByYear = {};
    for (int i = 0; i < years.length; i++) {
      storyCountsByYear[years[i]] = buildQuery(
        filters: {
          ...filtersWithoutYear,
          'year': years[i],
        },
      ).build().count();
    }

    storyCountsByYear[DateTime.now().year] ??= 0;
    return SplayTreeMap<int, int>.from(storyCountsByYear, (a, b) => b.compareTo(a));
  }

  Map<PathType, int> getStoryCountsByType({
    Map<String, dynamic>? filters,
  }) {
    AppLogger.info("Triggering $tableName#getStoryCountsByType 🍎");

    Map<PathType, int> storyCountsByType = {};

    for (PathType type in PathType.values) {
      storyCountsByType[type] = buildQuery(
        filters: {
          ...filters ?? {},
          'type': type.name,
        },
      ).build().count();
    }

    return storyCountsByType;
  }

  Map<int, int> getStoryCountByAssets({
    required List<int> assetIds,
  }) {
    AppLogger.info("Triggering $tableName#getStoryCountByAssets 🍊");

    Map<int, int> storyCountsByAssetIds = {};

    for (final assetId in assetIds) {
      storyCountsByAssetIds[assetId] = buildQuery(
        filters: {'asset': assetId},
      ).build().count();
    }

    return storyCountsByAssetIds;
  }

  Map<int, int> getStoryCountByTags({
    required List<int> tagIds,
    String? query,
    List<int>? years,
    List<String>? types,
  }) {
    AppLogger.info("Triggering $tableName#getStoryCountByTags 🍐");

    Map<int, int> storyCountsByTagIds = {};

    for (final tagId in tagIds) {
      storyCountsByTagIds[tagId] = buildQuery(
        filters: {
          'query': query,
          if (tagId != 0) 'tag': tagId,
          if (years != null && years.isNotEmpty) 'years': years,
          if (types != null && types.isNotEmpty) 'types': types,
        },
      ).build().count();
    }

    return storyCountsByTagIds;
  }

  int getStoryCountBy({
    Map<String, dynamic>? filters,
  }) {
    return buildQuery(filters: filters).build().count();
  }

  // - empty mean has story but no feeling
  // - null mean no story
  // - non-empty mean has story with feeling (emoji strings)
  Map<int, List<String>> getStoryFeelingByMonth({
    required int month,
    required int year,
    int? tagId,
    Map<int, String> feelingEmojiById = const {},
  }) {
    AppLogger.info("Triggering $tableName#getStoryFeelingByMonth 🍎");
    Map<int, List<String>> storyFeelingByMonth = {};

    Map<String, Object> filters = {
      'year': year,
      'month': month,
      'type': PathType.docs.name,
    };

    if (tagId != null) filters['tag'] = tagId;
    final result = buildQuery(filters: filters).build().find();

    for (final story in result) {
      final List<String> storyFeelings = (story.tags ?? [])
          .map((tagStr) => int.tryParse(tagStr))
          .whereType<int>()
          .map((id) => feelingEmojiById[id])
          .whereType<String>()
          .toSet()
          .toList();

      if (storyFeelings.isNotEmpty) {
        storyFeelingByMonth[story.day] ??= [];
        storyFeelingByMonth[story.day]!.addAll(storyFeelings);
      } else if (storyFeelingByMonth[story.day] == null) {
        storyFeelingByMonth[story.day] = ['exist_but_not_set'];
      }
    }

    storyFeelingByMonth.forEach((key, value) {
      storyFeelingByMonth[key] = storyFeelingByMonth[key]!.toSet().toList();
    });

    return storyFeelingByMonth;
  }

  @override
  Future<StoryDbModel?> set(
    StoryDbModel record, {
    bool runCallbacks = true,
    String? debugSource,
  }) async {
    StoryDbModel? saved = await super.set(record, runCallbacks: runCallbacks, debugSource: debugSource);

    // Only rebuild asset tags when story is published (not draft).
    // Draft stories auto-save frequently, so we skip this expensive operation.
    // Tag computation happens once when user click "Done".
    if (saved != null && !saved.draftStory && saved.assets?.isNotEmpty == true) {
      List<AssetDbModel> assets = await AssetDbModel.db
          .where(filters: {'ids': saved.assets})
          .then((e) => e?.items ?? []);

      for (int i = 0; i < assets.length; i++) {
        Set<int> tags = await computeStoriesTagsForAsset(assets[i]);
        final isLastAsset = i == assets.length - 1;
        await assets[i].copyWith(tags: tags.toList(), updatedAt: DateTime.now()).save(runCallbacks: isLastAsset);
      }
      AppLogger.info("🏷️ $runtimeType#set: computing tags for asset");
    }

    AppLogger.info("🚧 $runtimeType#set: latest ${saved?.latestContent?.id}, draft: ${saved?.draftContent?.id}");
    return saved;
  }

  Future<Set<int>> computeStoriesTagsForAsset(AssetDbModel asset) async {
    Set<int> tags =
        await buildQuery(filters: {'asset': asset.id}, returnDeleted: false)
            .build()
            .findAsync()
            .then((e) => e.map((e) => e.tags))
            .then((e) => e.expand((e) => e?.map((e) => int.tryParse(e) ?? 0) ?? <int>[]).toSet()) ??
        {};
    return tags;
  }

  @override
  Future<CollectionDbModel<StoryDbModel>?> where({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? options,
    bool returnDeleted = false,
  }) async {
    AppLogger.info("Triggering $tableName#where 🍎");

    List<StoryObjectBox> objects;
    QueryBuilder<StoryObjectBox>? queryBuilder = buildQuery(filters: filters, returnDeleted: returnDeleted);

    Query<StoryObjectBox>? query = queryBuilder.build();

    int? limit = filters != null && filters.containsKey('limit') ? filters['limit'] as int : null;
    if (limit != null) query.limit = limit;

    objects = await query.findAsync();

    Map<int, EventDbModel> events = await EventsBox()
        .buildQuery(
          filters: {'ids': objects.map((e) => e.eventId).whereType<int>().toList()},
        )
        .build()
        .findAsync()
        .then((query) async => {for (var item in query) item.id: await EventsBox().objectToModel(item)});

    options ??= {};
    options['events'] = events;

    List<StoryDbModel> docs = await objectsToModels(objects, options);
    return CollectionDbModel<StoryDbModel>(items: docs);
  }

  @override
  Future<StoryDbModel?> find(
    int id, {
    bool returnDeleted = false,
    String? debugSource,
  }) async {
    AppLogger.info("Triggering $tableName#find $id 🍎 from $debugSource");

    StoryObjectBox? object = box.get(id);
    if (object?.permanentlyDeletedAt != null && !returnDeleted) return null;

    Map<int, EventDbModel>? events;

    if (object?.eventId != null) {
      events = await EventsBox()
          .buildQuery(
            filters: {
              'ids': [object?.eventId],
            },
          )
          .build()
          .findAsync()
          .then((query) async => {for (var item in query) item.id: await EventsBox().objectToModel(item)});
    }

    if (object != null) {
      return objectToModel(object, events != null ? {'events': events} : null);
    } else {
      return null;
    }
  }

  @override
  QueryBuilder<StoryObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    List<int>? ids = filters?["ids"];
    int? createdYear = filters?["created_year"];
    String? query = filters?["query"];
    String? type = filters?["type"];
    List<String>? types = filters?["types"];
    int? year = filters?["year"];
    List<int>? years = filters?["years"];
    List<int>? excludeYears = filters?["exclude_years"];
    int? month = filters?["month"];
    int? day = filters?["day"];
    int? tag = filters?["tag"];
    List<int>? tags = filters?["tags"];
    String? galleryTemplateId = filters?["gallery_template_id"];
    int? template = filters?["template"];
    int? eventId = filters?["event_id"];
    int? asset = filters?["asset"];
    bool? starred = filters?["starred"];
    bool? pinned = filters?["pinned"];
    int? order = filters?["order"];
    bool priority = filters?["priority"] == true;
    List<int>? selectedYears = filters?["selected_years"];
    List<int>? yearsRange = filters?["years_range"];

    Condition<StoryObjectBox> conditions = StoryObjectBox_.id.notNull();

    if (ids != null && ids.isNotEmpty) {
      conditions = conditions.and(StoryObjectBox_.id.oneOf(ids));
    }

    if (!returnDeleted) conditions = conditions.and(StoryObjectBox_.permanentlyDeletedAt.isNull());
    if (tag != null) conditions = conditions.and(StoryObjectBox_.tags.containsElement(tag.toString()));

    if (tags != null && tags.isNotEmpty) {
      // AND logic: story must have ALL specified tags.
      for (final t in tags) {
        conditions = conditions.and(StoryObjectBox_.tags.containsElement(t.toString()));
      }
    }

    if (galleryTemplateId != null) {
      conditions = conditions.and(StoryObjectBox_.galleryTemplateId.equals(galleryTemplateId));
    }
    if (template != null) conditions = conditions.and(StoryObjectBox_.templateId.equals(template));
    if (eventId != null) conditions = conditions.and(StoryObjectBox_.eventId.equals(eventId));
    if (asset != null) conditions = conditions.and(StoryObjectBox_.assets.equals(asset));
    if (starred != null) conditions = conditions.and(StoryObjectBox_.starred.equals(starred));
    if (pinned != null && pinned == true) conditions = conditions.and(StoryObjectBox_.pinned.equals(pinned));
    if (pinned != null && pinned == false) {
      conditions = conditions.and(StoryObjectBox_.pinned.equals(pinned).or(StoryObjectBox_.pinned.isNull()));
    }
    if (type != null) conditions = conditions.and(StoryObjectBox_.type.equals(type));
    if (types != null) conditions = conditions.and(StoryObjectBox_.type.oneOf(types));
    if (year != null) conditions = conditions.and(StoryObjectBox_.year.equals(year));
    if (years != null) conditions = conditions.and(StoryObjectBox_.year.oneOf(years));
    if (excludeYears != null) conditions = conditions.and(StoryObjectBox_.year.notOneOf(excludeYears));
    if (month != null) conditions = conditions.and(StoryObjectBox_.month.equals(month));
    if (day != null) conditions = conditions.and(StoryObjectBox_.day.equals(day));
    if (createdYear != null) {
      conditions = conditions.and(
        StoryObjectBox_.createdAt.betweenDate(
          DateTime(createdYear, 1, 1),
          DateTime(createdYear, 12, 31, 23, 59, 59),
        ),
      );
    }

    if (query != null) {
      conditions = conditions.and(
        StoryObjectBox_.searchMetadata.contains(query.toLowerCase(), caseSensitive: false),
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
