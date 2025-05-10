import 'dart:convert';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/objectbox.g.dart';

class AssetsBox extends BaseBox<AssetObjectBox, AssetDbModel> {
  @override
  String get tableName => "assets";

  @override
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) async {
    Condition<AssetObjectBox>? conditions = AssetObjectBox_.id.notNull();

    if (fromThisDeviceOnly == true) {
      conditions = conditions.and(AssetObjectBox_.lastSavedDeviceId.equals(kDeviceInfo.id));
    }

    Query<AssetObjectBox> query =
        box.query(conditions).order(AssetObjectBox_.updatedAt, flags: Order.descending).build();
    AssetObjectBox? object = await query.findFirstAsync();
    return object?.updatedAt;
  }

  @override
  QueryBuilder<AssetObjectBox> buildQuery({Map<String, dynamic>? filters}) {
    Condition<AssetObjectBox> conditions =
        AssetObjectBox_.id.notNull().and(AssetObjectBox_.permanentlyDeletedAt.isNull());

    QueryBuilder<AssetObjectBox> queryBuilder = box.query(conditions);
    queryBuilder = queryBuilder.order(AssetObjectBox_.id, flags: Order.descending);

    return queryBuilder;
  }

  @override
  AssetDbModel modelFromJson(Map<String, dynamic> json) => AssetDbModel.fromJson(json);

  @override
  Future<AssetObjectBox> modelToObject(AssetDbModel model, [Map<String, dynamic>? options]) async {
    return AssetObjectBox(
      id: model.id,
      originalSource: model.originalSource,
      cloudDestinations: jsonEncode(model.cloudDestinations),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  @override
  Future<List<AssetObjectBox>> modelsToObjects(
    List<AssetDbModel> models, [
    Map<String, dynamic>? options,
  ]) async {
    return models.map((model) {
      return AssetObjectBox(
        id: model.id,
        originalSource: model.originalSource,
        cloudDestinations: jsonEncode(model.cloudDestinations),
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
      );
    }).toList();
  }

  @override
  Future<AssetDbModel> objectToModel(AssetObjectBox object, [Map<String, dynamic>? options]) async {
    return AssetDbModel(
      id: object.id,
      originalSource: object.originalSource,
      cloudDestinations: decodeCloudDestinations(object),
      createdAt: object.createdAt,
      updatedAt: object.updatedAt,
      lastSavedDeviceId: object.lastSavedDeviceId,
    );
  }

  Map<String, Map<String, Map<String, String>>> decodeCloudDestinations(AssetObjectBox object) {
    dynamic result = jsonDecode(object.cloudDestinations);

    Map<String, Map<String, Map<String, String>>> decodeData = {};
    if (result is Map<String, dynamic>) {
      result.forEach((l1, value) {
        decodeData[l1] ??= {};
        if (value is Map<String, dynamic>) {
          value.forEach((l2, value) {
            decodeData[l1]![l2] ??= {};
            if (value is Map<String, dynamic>) {
              value.forEach((l3, value) {
                decodeData[l1]![l2]![l3] = value.toString();
              });
            }
          });
        }
      });
    }

    return decodeData;
  }

  @override
  Future<List<AssetDbModel>> objectsToModels(
    List<AssetObjectBox> objects, [
    Map<String, dynamic>? options,
  ]) async {
    return objects.map((object) {
      return AssetDbModel(
        id: object.id,
        originalSource: object.originalSource,
        cloudDestinations: decodeCloudDestinations(object),
        createdAt: object.createdAt,
        updatedAt: object.updatedAt,
        lastSavedDeviceId: object.lastSavedDeviceId,
      );
    }).toList();
  }
}
