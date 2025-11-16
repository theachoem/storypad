import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
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

  CollectionDbModel<TagDbModel>? initialTags;

  @override
  Future<void> initilize() async {
    await super.initilize();
    initialTags = await where();
  }

  @override
  Future<CollectionDbModel<TagDbModel>?> where({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? options,
    bool returnDeleted = false,
  }) async {
    CollectionDbModel<TagDbModel>? result = await super.where(
      filters: filters,
      returnDeleted: returnDeleted,
    );

    List<TagDbModel> items = result?.items ?? [];

    for (int i = 0; i < items.length; i++) {
      if (items[i].starred == null) {
        items[i] = items[i].copyWith(starred: true);
        update(items[i], runCallbacks: i == items.length - 1);
      }
    }

    return CollectionDbModel(
      items: items,
    );
  }

  @override
  QueryBuilder<TagObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? createdYear = filters?["created_year"];
    int? order = filters?["order"];

    Condition<TagObjectBox> conditions = TagObjectBox_.id.notNull();
    if (!returnDeleted) conditions = conditions.and(TagObjectBox_.permanentlyDeletedAt.isNull());
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
