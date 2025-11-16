import 'dart:convert';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/adapters/objectbox/base_box.dart';
import 'package:storypad/core/databases/adapters/objectbox/entities.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/objectbox.g.dart';

class AssetsBox extends BaseBox<AssetObjectBox, AssetDbModel> {
  @override
  String get tableName => "assets";

  @override
  QueryIntegerProperty<AssetObjectBox> get idProperty => AssetObjectBox_.id;

  @override
  QueryStringProperty<AssetObjectBox> get lastSavedDeviceIdProperty => AssetObjectBox_.lastSavedDeviceId;

  @override
  QueryDateProperty<AssetObjectBox> get permanentlyDeletedAtProperty => AssetObjectBox_.permanentlyDeletedAt;

  @override
  QueryBuilder<AssetObjectBox> buildQuery({
    Map<String, dynamic>? filters,
    bool returnDeleted = false,
  }) {
    int? createdYear = filters?["created_year"];
    AssetType? type = filters?["type"];
    List<int>? ids = filters?["ids"]?.cast<int>();
    int? tag = filters?["tag"];

    Condition<AssetObjectBox> conditions = AssetObjectBox_.id.notNull();

    if (!returnDeleted) conditions = conditions.and(AssetObjectBox_.permanentlyDeletedAt.isNull());
    if (type == AssetType.image) {
      conditions = conditions.and(
        AssetObjectBox_.type.equals(AssetType.image.name).or(AssetObjectBox_.type.isNull()),
      );
    } else if (type != null) {
      conditions = conditions.and(AssetObjectBox_.type.equals(type.name));
    }

    if (tag != null) {
      conditions = conditions.and(AssetObjectBox_.tags.equals(tag));
    }

    if (ids != null && ids.isNotEmpty) {
      conditions = conditions.and(AssetObjectBox_.id.oneOf(ids));
    }

    if (createdYear != null) {
      conditions = conditions.and(
        AssetObjectBox_.createdAt.betweenDate(
          DateTime(createdYear, 1, 1),
          DateTime(createdYear, 12, 31, 23, 59, 59),
        ),
      );
    }

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
      type: model.type.name,
      tags: model.tags,
      metadata: model.metadata != null ? jsonEncode(model.metadata) : null,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      permanentlyDeletedAt: model.permanentlyDeletedAt,
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
        type: model.type.name,
        tags: model.tags,
        metadata: model.metadata != null ? jsonEncode(model.metadata) : null,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
        permanentlyDeletedAt: model.permanentlyDeletedAt,
      );
    }).toList();
  }

  @override
  Future<AssetDbModel> objectToModel(AssetObjectBox object, [Map<String, dynamic>? options]) async {
    return AssetDbModel(
      id: object.id,
      originalSource: object.originalSource,
      cloudDestinations: decodeCloudDestinations(object),
      type: AssetType.fromValue(object.type),
      tags: object.tags,
      metadata: object.metadata != null ? jsonDecode(object.metadata!) as Map<String, dynamic> : null,
      createdAt: object.createdAt,
      updatedAt: object.updatedAt,
      lastSavedDeviceId: object.lastSavedDeviceId,
      permanentlyDeletedAt: object.permanentlyDeletedAt,
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
        type: AssetType.fromValue(object.type),
        tags: object.tags,
        metadata: object.metadata != null ? jsonDecode(object.metadata!) as Map<String, dynamic> : null,
        createdAt: object.createdAt,
        updatedAt: object.updatedAt,
        lastSavedDeviceId: object.lastSavedDeviceId,
        permanentlyDeletedAt: object.permanentlyDeletedAt,
      );
    }).toList();
  }
}
