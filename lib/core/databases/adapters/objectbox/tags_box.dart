import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/objectbox.g.dart';

part './helpers/tags_box_transformer.dart';

class TagsBox extends BaseBox<TagObjectBox, TagDbModel> {
  @override
  String get tableName => "tags";

  CollectionDbModel<TagDbModel>? initialTags;

  @override
  Future<void> initilize() async {
    await super.initilize();
    initialTags = await where();
  }

  @override
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) async {
    Condition<TagObjectBox>? conditions = TagObjectBox_.id.notNull();

    if (fromThisDeviceOnly == true) {
      conditions.and(TagObjectBox_.lastSavedDeviceId.equals(kDeviceInfo.id));
    }

    Query<TagObjectBox> query = box.query(conditions).order(TagObjectBox_.updatedAt, flags: Order.descending).build();
    TagObjectBox? object = await query.findFirstAsync();
    return object?.updatedAt;
  }

  @override
  Future<CollectionDbModel<TagDbModel>?> where({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? options,
  }) async {
    CollectionDbModel<TagDbModel>? result = await super.where(filters: filters);
    List<TagDbModel> items = result?.items ?? [];

    for (int i = 0; i < items.length; i++) {
      if (items[i].starred == null) {
        items[i] = items[i].copyWith(starred: true);
        update(items[i]);
      }
    }

    return CollectionDbModel(
      items: items,
    );
  }

  @override
  QueryBuilder<TagObjectBox> buildQuery({
    Map<String, dynamic>? filters,
  }) {
    int? order = filters?["order"];
    Condition<TagObjectBox> conditions = TagObjectBox_.id.notNull().and(TagObjectBox_.permanentlyDeletedAt.isNull());

    QueryBuilder<TagObjectBox> queryBuilder = box.query(conditions);

    queryBuilder.order(TagObjectBox_.index, flags: order ?? 0);

    return queryBuilder;
  }

  @override
  Future<Map<String, int>> getDeletedRecords() async {
    Condition<TagObjectBox> conditions = TagObjectBox_.permanentlyDeletedAt.notNull();
    List<TagObjectBox> result =
        await box.query(conditions).order(TagObjectBox_.id, flags: Order.descending).build().findAsync();
    return {
      for (final data in result) data.id.toString(): data.permanentlyDeletedAt!.millisecondsSinceEpoch,
    };
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
