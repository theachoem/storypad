// ignore_for_file: library_private_types_in_public_api

import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/initializers/device_info_initializer.dart';
import 'package:storypad/objectbox.g.dart';

class PreferencesBox extends BaseBox<PreferenceObjectBox, PreferenceDbModel> {
  _DefinedPreference get nickname => _DefinedPreference(id: 2, key: 'nickname');

  @override
  String get tableName => "preferences";

  @override
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) async {
    Condition<PreferenceObjectBox>? conditions = PreferenceObjectBox_.id.notNull();

    if (fromThisDeviceOnly == true) {
      conditions = conditions.and(PreferenceObjectBox_.lastSavedDeviceId.equals(kDeviceInfo.id));
    }

    Query<PreferenceObjectBox> query =
        box.query(conditions).order(PreferenceObjectBox_.updatedAt, flags: Order.descending).build();
    PreferenceObjectBox? object = await query.findFirstAsync();
    return object?.updatedAt;
  }

  @override
  QueryBuilder<PreferenceObjectBox> buildQuery({Map<String, dynamic>? filters}) {
    Condition<PreferenceObjectBox> conditions =
        PreferenceObjectBox_.id.notNull().and(PreferenceObjectBox_.permanentlyDeletedAt.isNull());
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
        lastSavedDeviceId: object.lastSavedDeviceId,
      );
    }).toList();
  }
}

class _DefinedPreference {
  final int id;
  final String key;

  _DefinedPreference({
    required this.id,
    required this.key,
  });

  String? get() {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);
    return record?.value;
  }

  void set(String value) {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);
    PreferencesBox().box.put(PreferenceObjectBox(
          id: id,
          key: key,
          value: value,
          createdAt: record?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ));
  }

  void touch() {
    PreferenceObjectBox? record = PreferencesBox().box.get(id);
    PreferencesBox().box.put(PreferenceObjectBox(
          id: id,
          key: key,
          value: DateTime.now().toIso8601String(),
          createdAt: record?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ));
  }
}
