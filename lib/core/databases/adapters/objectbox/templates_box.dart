import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/adapters/objectbox/helpers/story_content_helper.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/objectbox.g.dart';

part 'helpers/templates_box_transformer.dart';

class TemplatesBox extends BaseBox<TemplateObjectBox, TemplateDbModel> {
  @override
  String get tableName => "templates";

  @override
  QueryIntegerProperty<TemplateObjectBox> get idProperty => TemplateObjectBox_.id;

  @override
  QueryStringProperty<TemplateObjectBox> get lastSavedDeviceIdProperty => TemplateObjectBox_.lastSavedDeviceId;

  @override
  QueryDateProperty<TemplateObjectBox> get permanentlyDeletedAtProperty => TemplateObjectBox_.permanentlyDeletedAt;

  @override
  QueryBuilder<TemplateObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? createdYear = filters?["created_year"];
    int? order = filters?["order"];
    bool? archived = filters?["archived"] == true;
    String? galleryTemplateId = filters?["gallery_template_id"];

    Condition<TemplateObjectBox> conditions = TemplateObjectBox_.id.notNull();
    if (!returnDeleted) conditions = conditions.and(TemplateObjectBox_.permanentlyDeletedAt.isNull());

    if (archived == true) {
      conditions = conditions.and(TemplateObjectBox_.archivedAt.notNull());
    } else {
      conditions = conditions.and(TemplateObjectBox_.archivedAt.isNull());
    }

    if (galleryTemplateId != null) {
      conditions = conditions.and(TemplateObjectBox_.galleryTemplateId.equals(galleryTemplateId));
    }

    if (createdYear != null) {
      conditions = conditions.and(
        TemplateObjectBox_.createdAt.betweenDate(
          DateTime(createdYear, 1, 1),
          DateTime(createdYear, 12, 31, 23, 59, 59),
        ),
      );
    }

    QueryBuilder<TemplateObjectBox> queryBuilder = box.query(conditions);

    queryBuilder.order(TemplateObjectBox_.index, flags: order ?? 0);

    return queryBuilder;
  }

  @override
  TemplateDbModel modelFromJson(Map<String, dynamic> json) {
    return TemplateDbModel.fromJson(json);
  }

  @override
  Future<List<TemplateDbModel>> objectsToModels(List<TemplateObjectBox> objects, [Map<String, dynamic>? options]) {
    return compute(_objectsToModels, {'objects': objects, 'options': options});
  }

  @override
  Future<List<TemplateObjectBox>> modelsToObjects(List<TemplateDbModel> models, [Map<String, dynamic>? options]) {
    return compute(_modelsToObjects, {'models': models, 'options': options});
  }

  @override
  Future<TemplateObjectBox> modelToObject(TemplateDbModel model, [Map<String, dynamic>? options]) {
    return compute(_modelToObject, {'model': model, 'options': options});
  }

  @override
  Future<TemplateDbModel> objectToModel(TemplateObjectBox object, [Map<String, dynamic>? options]) {
    return compute(_objectToModel, {'object': object, 'options': options});
  }
}
