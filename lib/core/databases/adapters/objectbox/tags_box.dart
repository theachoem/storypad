import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/objectbox.g.dart';

part './helpers/tags_box_transformer.dart';

class TagsBox extends BaseBox<TagObjectBox, TagDbModel> {
  @override
  String get tableName => "tags";

  @override
  QueryIntegerProperty<TagObjectBox> get idProperty => TagObjectBox_.id;

  @override
  QueryStringProperty<TagObjectBox> get lastSavedDeviceIdProperty => TagObjectBox_.lastSavedDeviceId;

  @override
  QueryDateProperty<TagObjectBox> get permanentlyDeletedAtProperty => TagObjectBox_.permanentlyDeletedAt;

  CollectionDbModel<TagDbModel>? _initialTags;
  CollectionDbModel<TagDbModel>? getInitialTagsAndClear() {
    final tags = _initialTags;
    _initialTags = null;
    return tags;
  }

  @override
  Future<void> initilize() async {
    await super.initilize();
    _initialTags = await where();

    // migration emoji tags with category_id null to 1 (feeling category)
    // this is just in case if user have import tags from latest app version to
    // an older app version that doesn't have category_id field
    final conditions = TagObjectBox_.id
        .notNull()
        .and(TagObjectBox_.permanentlyDeletedAt.notNull())
        .and(TagObjectBox_.categoryId.isNull())
        .and(TagObjectBox_.emoji.notNull());

    final count = box.query(conditions).build().count();
    if (count > 0) {
      box.putMany(
        box.query(conditions).build().find().map((e) {
          e.categoryId = 1;
          return e;
        }).toList(),
      );

      AppLogger.info(
        "$runtimeType#initialize Migrated $count emoji tags with null category_id to category_id 1 (feeling category)",
      );
    }
  }

  @override
  QueryBuilder<TagObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? createdYear = filters?["created_year"];
    int? order = filters?["order"];
    int? categoryId = filters?["category_id"];

    Condition<TagObjectBox> conditions = TagObjectBox_.id.notNull();
    if (!returnDeleted) conditions = conditions.and(TagObjectBox_.permanentlyDeletedAt.isNull());

    if (categoryId != null) {
      conditions = conditions.and(TagObjectBox_.categoryId.equals(categoryId));
    }

    if (createdYear != null) {
      conditions = conditions.and(
        TagObjectBox_.createdAt.betweenDate(
          DateTime(createdYear, 1, 1),
          DateTime(createdYear, 12, 31, 23, 59, 59),
        ),
      );
    }

    QueryBuilder<TagObjectBox> queryBuilder = box.query(conditions);
    queryBuilder.order(TagObjectBox_.index, flags: order ?? 0);

    // Duplicate indexes are possible while a multi-device sync settles, and the order of
    // tied rows is otherwise undefined. Break the tie on createdAt so every device lists
    // them the same way instead of inventing a different order each read.
    //
    // Example: a tag index is a single sequence, but backups are split into one file per
    // createdAt year. Reordering to [Work(2021), Home(2026)] writes index 0 to the 2021
    // file and index 1 to the 2026 file. If only the 2026 file reaches the other device,
    // it merges Home=1 onto a Work that still has its old index 1:
    //
    //   id=Work  index=1  createdAt=2021-03-04
    //   id=Home  index=1  createdAt=2026-01-09
    //
    // Ordering by index alone leaves those two rows in whatever order the query happens
    // to return, and TagsProvider._reindex then writes that arbitrary order back as the
    // real one. With createdAt as a tiebreaker the result is at least stable and
    // identical on every device, so a later reorder sticks instead of fighting the reads.
    queryBuilder.order(TagObjectBox_.createdAt, flags: order ?? 0);

    return queryBuilder;
  }

  @override
  TagDbModel modelFromJson(Map<String, dynamic> json) {
    return TagDbModel.fromJson(json);
  }

  @override
  Future<List<TagDbModel>> objectsToModels(List<TagObjectBox> objects, [Map<String, dynamic>? options]) {
    return compute(_objectsToModels, {'objects': objects, 'options': options});
  }

  @override
  Future<List<TagObjectBox>> modelsToObjects(List<TagDbModel> models, [Map<String, dynamic>? options]) {
    return compute(_modelsToObjects, {'models': models, 'options': options});
  }

  @override
  Future<TagObjectBox> modelToObject(TagDbModel model, [Map<String, dynamic>? options]) {
    return compute(_modelToObject, {'model': model, 'options': options});
  }

  @override
  Future<TagDbModel> objectToModel(TagObjectBox object, [Map<String, dynamic>? options]) {
    return compute(_objectToModel, {'object': object, 'options': options});
  }
}
