import 'dart:convert';
import 'package:storypad/core/databases/adapters/objectbox/preferences_box.dart';
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
    List<AssetType>? types = filters?["types"]?.cast<AssetType>();
    int? version = filters?["version"];
    List<int>? ids = filters?["ids"]?.cast<int>();
    int? tag = filters?["tag"];

    Condition<AssetObjectBox> conditions = AssetObjectBox_.id.notNull();

    if (!returnDeleted) conditions = conditions.and(AssetObjectBox_.permanentlyDeletedAt.isNull());
    if (types != null && types.isNotEmpty) {
      // Legacy rows saved before `type` existed have a null type and were always images.
      Condition<AssetObjectBox> typeCondition = AssetObjectBox_.type.oneOf(types.map((t) => t.name).toList());
      if (types.contains(AssetType.image)) {
        typeCondition = typeCondition.or(AssetObjectBox_.type.isNull());
      }
      conditions = conditions.and(typeCondition);
    } else if (type == AssetType.image) {
      conditions = conditions.and(
        AssetObjectBox_.type.equals(AssetType.image.name).or(AssetObjectBox_.type.isNull()),
      );
    } else if (type != null) {
      conditions = conditions.and(AssetObjectBox_.type.equals(type.name));
    }

    if (version == 1) {
      conditions = conditions.and(AssetObjectBox_.version.equals(1).or(AssetObjectBox_.version.isNull()));
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
      width: model.width,
      height: model.height,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      permanentlyDeletedAt: model.permanentlyDeletedAt,
      version: model.version ?? 1,
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
        width: model.width,
        height: model.height,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
        permanentlyDeletedAt: model.permanentlyDeletedAt,
        version: model.version ?? 1,
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
      width: object.width,
      height: object.height,
      createdAt: object.createdAt,
      updatedAt: object.updatedAt,
      lastSavedDeviceId: object.lastSavedDeviceId,
      permanentlyDeletedAt: object.permanentlyDeletedAt,
      version: object.version ?? 1,
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
        width: object.width,
        height: object.height,
        createdAt: object.createdAt,
        updatedAt: object.updatedAt,
        lastSavedDeviceId: object.lastSavedDeviceId,
        permanentlyDeletedAt: object.permanentlyDeletedAt,
      );
    }).toList();
  }

  @override
  Future<void> afterCommit([int? id, AssetDbModel? model]) async {
    // Invalidate storage quota cache after any change to assets.
    // This will allow StorageManagementView to fetch the latest storage usage data on next load.
    PreferencesBox().invalidateStorageQuotaCache();

    await super.afterCommit(id, model);
  }

  // In-memory only; keyed by asset id. Caches misses too (as `null`) so an
  // asset with no persisted width/height doesn't repeat a native read every lookup.
  final Map<int, double?> _aspectRatioCache = {};

  /// Reads an image/video asset's persisted aspect ratio, derived from the
  /// dedicated `width`/`height` columns (see
  /// `InsertFileToDbService.insertImage`/`insertVideo`), without going through
  /// `find()`/`objectToModel()`, which are `Future`-returning by interface
  /// contract -- this is a genuinely synchronous read (plain `box.get` field
  /// access, no JSON decode needed) so tiles can size themselves correctly on
  /// first build, with no async gap at all. Checks the in-memory cache first
  /// -- warmed by [preloadAspectRatios] wherever a batch of assets is about to
  /// be rendered (e.g. a loaded story list), so most lookups hit the cache
  /// instead of a fresh native read.
  double? findAspectRatioSync(int id) {
    if (_aspectRatioCache.containsKey(id)) return _aspectRatioCache[id];
    return _aspectRatioCache[id] = _aspectRatioOf(box.get(id));
  }

  /// Bulk-warms the aspect-ratio cache for many assets in a single native
  /// call (`Box.getMany`) instead of one `box.get` per asset -- call this
  /// once after loading a batch of content that will render asset tiles (a
  /// story list, a library page, etc.), before those tiles build.
  void preloadAspectRatios(Iterable<int> ids) {
    final idsToLoad = ids.where((id) => !_aspectRatioCache.containsKey(id)).toSet().toList();
    if (idsToLoad.isEmpty) return;

    final objects = box.getMany(idsToLoad);
    for (var i = 0; i < idsToLoad.length; i++) {
      _aspectRatioCache[idsToLoad[i]] = _aspectRatioOf(objects[i]);
    }
  }

  double? _aspectRatioOf(AssetObjectBox? object) {
    final width = object?.width;
    final height = object?.height;
    if (width == null || height == null || height <= 0) return null;
    return width / height;
  }
}
