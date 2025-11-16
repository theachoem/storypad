// ignore_for_file: library_private_types_in_public_api

import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/objectbox.g.dart';

part './helpers/defined_preference.dart';

class PreferencesBox extends BaseBox<PreferenceObjectBox, PreferenceDbModel> {
  _DefinedPreference get nickname => _DefinedPreference(id: 2, key: 'nickname');

  @override
  String get tableName => "preferences";

  @override
  QueryIntegerProperty<PreferenceObjectBox> get idProperty => PreferenceObjectBox_.id;

  @override
  QueryStringProperty<PreferenceObjectBox> get lastSavedDeviceIdProperty => PreferenceObjectBox_.lastSavedDeviceId;

  @override
  QueryDateProperty<PreferenceObjectBox> get permanentlyDeletedAtProperty => PreferenceObjectBox_.permanentlyDeletedAt;

  @override
  QueryBuilder<PreferenceObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? createdYear = filters?["created_year"];

    Condition<PreferenceObjectBox> conditions = PreferenceObjectBox_.id.notNull();
    if (!returnDeleted) conditions = conditions.and(PreferenceObjectBox_.permanentlyDeletedAt.isNull());
    if (createdYear != null) {
      conditions = conditions.and(
        PreferenceObjectBox_.createdAt.betweenDate(
          DateTime(createdYear, 1, 1),
          DateTime(createdYear, 12, 31, 23, 59, 59),
        ),
      );
    }

    return box.query(conditions);
  }

  @override
  PreferenceDbModel modelFromJson(Map<String, dynamic> json) => PreferenceDbModel.fromJson(json);

  @override
  Future<PreferenceObjectBox> modelToObject(PreferenceDbModel model, [Map<String, dynamic>? options]) async {
    return PreferenceObjectBox(
      id: model.id,
      key: model.key,
      value: model.value,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  @override
  Future<List<PreferenceObjectBox>> modelsToObjects(
    List<PreferenceDbModel> models, [
    Map<String, dynamic>? options,
  ]) async {
    return models.map((model) {
      return PreferenceObjectBox(
        id: model.id,
        key: model.key,
        value: model.value,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
      );
    }).toList();
  }

  @override
  Future<PreferenceDbModel> objectToModel(PreferenceObjectBox object, [Map<String, dynamic>? options]) async {
    return PreferenceDbModel(
      id: object.id,
      key: object.key,
      value: object.value,
      createdAt: object.createdAt,
      updatedAt: object.updatedAt,
      permanentlyDeletedAt: object.permanentlyDeletedAt,
      lastSavedDeviceId: object.lastSavedDeviceId,
    );
  }

  @override
  Future<List<PreferenceDbModel>> objectsToModels(
    List<PreferenceObjectBox> objects, [
    Map<String, dynamic>? options,
  ]) async {
    return objects.map((object) {
      return PreferenceDbModel(
        id: object.id,
        key: object.key,
        value: object.value,
        createdAt: object.createdAt,
        updatedAt: object.updatedAt,
        permanentlyDeletedAt: object.permanentlyDeletedAt,
        lastSavedDeviceId: object.lastSavedDeviceId,
      );
    }).toList();
  }
}
