import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/initializers/device_info_initializer.dart';
import 'package:storypad/objectbox.g.dart';

class TagsBox extends BaseBox<TagObjectBox, TagDbModel> {
  @override
  String get tableName => "tags";

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
    List<TagDbModel> items = [...result?.items ?? []]..sort((a, b) => a.index.compareTo(b.index));

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
    Condition<TagObjectBox> conditions = TagObjectBox_.id.notNull().and(TagObjectBox_.permanentlyDeletedAt.isNull());
    return box.query(conditions);
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

List<TagDbModel> _objectsToModels(Map<String, dynamic> options) {
  List<TagObjectBox> objects = options['objects'];
  return objects.map((object) => _objectToModel({'object': object})).toList();
}

List<TagObjectBox> _modelsToObjects(Map<String, dynamic> options) {
  List<TagObjectBox> models = options['models'];
  return models.map((model) => _modelToObject({'model': model})).toList();
}

TagObjectBox _modelToObject(Map<String, dynamic> options) {
  TagDbModel model = options['model'];

  return TagObjectBox(
    id: model.id,
    title: model.title,
    index: model.index,
    version: model.version,
    starred: model.starred,
    emoji: model.emoji,
    createdAt: model.createdAt,
    updatedAt: model.updatedAt,
  );
}

TagDbModel _objectToModel(Map<String, dynamic> options) {
  TagObjectBox object = options['object'];

  return TagDbModel(
    id: object.id,
    version: object.version,
    title: object.title,
    starred: object.starred,
    emoji: object.emoji,
    createdAt: object.createdAt,
    updatedAt: object.updatedAt,
    lastSavedDeviceId: object.lastSavedDeviceId,
  );
}
