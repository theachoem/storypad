import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';
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
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) async {
    Condition<TemplateObjectBox>? conditions = TemplateObjectBox_.id.notNull();

    if (fromThisDeviceOnly == true) {
      conditions.and(TemplateObjectBox_.lastSavedDeviceId.equals(kDeviceInfo.id));
    }

    Query<TemplateObjectBox> query =
        box.query(conditions).order(TemplateObjectBox_.updatedAt, flags: Order.descending).build();
    TemplateObjectBox? object = await query.findFirstAsync();
    return object?.updatedAt;
  }

  @override
  QueryBuilder<TemplateObjectBox> buildQuery({
    Map<String, dynamic>? filters,
  }) {
    int? order = filters?["order"];
    Condition<TemplateObjectBox> conditions =
        TemplateObjectBox_.id.notNull().and(TemplateObjectBox_.permanentlyDeletedAt.isNull());

    QueryBuilder<TemplateObjectBox> queryBuilder = box.query(conditions);

    queryBuilder.order(TemplateObjectBox_.index, flags: order ?? 0);

    return queryBuilder;
  }

  @override
  Future<Map<String, int>> getDeletedRecords() async {
    Condition<TemplateObjectBox> conditions = TemplateObjectBox_.permanentlyDeletedAt.notNull();
    List<TemplateObjectBox> result =
        await box.query(conditions).order(TemplateObjectBox_.id, flags: Order.descending).build().findAsync();
    return {
      for (final data in result) data.id.toString(): data.permanentlyDeletedAt!.millisecondsSinceEpoch,
    };
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
