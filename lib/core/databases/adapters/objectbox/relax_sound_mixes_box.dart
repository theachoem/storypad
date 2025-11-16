import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/relax_sound_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/objectbox.g.dart';

part 'helpers/relax_sound_mixes_box_transformer.dart';

class RelaxSoundMixesBox extends BaseBox<RelaxSoundMixBox, RelaxSoundMixModel> {
  @override
  String get tableName => "relax_sound_mixes";

  @override
  QueryIntegerProperty<RelaxSoundMixBox> get idProperty => RelaxSoundMixBox_.id;

  @override
  QueryStringProperty<RelaxSoundMixBox> get lastSavedDeviceIdProperty => RelaxSoundMixBox_.lastSavedDeviceId;

  @override
  QueryDateProperty<RelaxSoundMixBox> get permanentlyDeletedAtProperty => RelaxSoundMixBox_.permanentlyDeletedAt;

  @override
  QueryBuilder<RelaxSoundMixBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? createdYear = filters?["created_year"];

    Condition<RelaxSoundMixBox> conditions = RelaxSoundMixBox_.id.notNull();
    if (!returnDeleted) conditions = conditions.and(RelaxSoundMixBox_.permanentlyDeletedAt.isNull());
    if (createdYear != null) {
      conditions = conditions.and(
        RelaxSoundMixBox_.createdAt.betweenDate(
          DateTime(createdYear, 1, 1),
          DateTime(createdYear, 12, 31, 23, 59, 59),
        ),
      );
    }

    QueryBuilder<RelaxSoundMixBox> queryBuilder = box.query(conditions);
    queryBuilder.order(RelaxSoundMixBox_.index);

    return queryBuilder;
  }

  @override
  RelaxSoundMixModel modelFromJson(Map<String, dynamic> json) {
    return RelaxSoundMixModel.fromJson(json);
  }

  @override
  Future<List<RelaxSoundMixModel>> objectsToModels(List<RelaxSoundMixBox> objects, [Map<String, dynamic>? options]) {
    return compute(_objectsToModels, {'objects': objects, 'options': options});
  }

  @override
  Future<List<RelaxSoundMixBox>> modelsToObjects(List<RelaxSoundMixModel> models, [Map<String, dynamic>? options]) {
    return compute(_modelsToObjects, {'models': models, 'options': options});
  }

  @override
  Future<RelaxSoundMixBox> modelToObject(RelaxSoundMixModel model, [Map<String, dynamic>? options]) {
    return compute(_modelToObject, {'model': model, 'options': options});
  }

  @override
  Future<RelaxSoundMixModel> objectToModel(RelaxSoundMixBox object, [Map<String, dynamic>? options]) {
    return compute(_objectToModel, {'object': object, 'options': options});
  }
}
