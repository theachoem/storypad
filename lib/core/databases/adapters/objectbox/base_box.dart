import 'dart:io';
import 'package:spooky/core/databases/adapters/base_db_adapter.dart';
import 'package:spooky/core/databases/adapters/objectbox/entities.dart';
import 'package:spooky/core/databases/models/base_db_model.dart';
import 'package:spooky/core/databases/models/collection_db_model.dart';
import 'package:spooky/core/services/file_service.dart';
import 'package:spooky/objectbox.g.dart';

abstract class BaseBox<B extends BaseObjectBox, T extends BaseDbModel> extends BaseDbAdapter<T> {
  @override
  String get tableName;

  static Store? _store;
  Store get store => _store!;

  Box<B>? _box;

  Box<B> get box {
    _box ??= store.box<B>();
    return _box!;
  }

  Future<B> modelToObject(T model, [Map<String, dynamic>? options]);
  Future<List<B>> modelsToObjects(List<T> models, [Map<String, dynamic>? options]);

  Future<T> objectToModel(B object, [Map<String, dynamic>? options]);
  Future<List<T>> objectsToModels(
    List<B> objects, [
    Map<String, dynamic>? options,
  ]);

  Future<void> initilize() async {
    if (_store != null) return;

    Directory directory = Directory(FileService.addDirectory("database/objectbox"));
    if (!await directory.exists()) await directory.create(recursive: true);

    _store = await openStore(
      directory: directory.path,
      macosApplicationGroup: '24KJ877SZ9',
    );
  }

  @override
  Future<T?> find(int id, {bool returnDeleted = false}) async {
    B? object = box.get(id);
    if (object?.permanentlyDeletedAt != null && !returnDeleted) return null;

    if (object != null) {
      return objectToModel(object);
    } else {
      return null;
    }
  }

  @override
  bool hasDeleted(int id) {
    return box.get(id)?.permanentlyDeletedAt != null;
  }

  QueryBuilder<B> buildQuery({
    Map<String, dynamic>? filters,
  });

  @override
  Future<int> count({
    Map<String, dynamic>? filters,
  }) async {
    QueryBuilder<B>? queryBuilder = buildQuery(filters: filters);
    Query<B>? query = queryBuilder.build();
    return query.count();
  }

  @override
  Future<CollectionDbModel<T>?> where({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? options,
  }) async {
    List<B> objects;
    QueryBuilder<B>? queryBuilder = buildQuery(filters: filters);

    Query<B>? query = queryBuilder.build();
    objects = await query.findAsync();

    List<T> docs = await objectsToModels(objects, options);
    return CollectionDbModel<T>(items: docs);
  }

  @override
  Future<T?> set(
    T record, {
    bool runCallbacks = true,
  }) async {
    B constructed = await modelToObject(record);
    await box.putAsync(constructed, mode: PutMode.put);
    if (runCallbacks) afterCommit(record.id);
    return record;
  }

  @override
  Future<void> setAll(List<T> records) async {
    List<B> objects = await modelsToObjects(records.whereType<T>().toList());
    await box.putManyAsync(objects, mode: PutMode.put);
  }

  @override
  Future<T?> update(
    T record, {
    bool runCallbacks = true,
  }) async {
    B constructed = await modelToObject(record);
    await box.putAsync(constructed, mode: PutMode.update);
    if (runCallbacks) afterCommit(record.id);
    return record;
  }

  @override
  Future<T?> create(
    T record, {
    bool runCallbacks = true,
  }) async {
    B constructed = await modelToObject(record);
    await box.putAsync(constructed, mode: PutMode.insert);
    if (runCallbacks) afterCommit(record.id);
    return record;
  }

  @override
  Future<T?> delete(
    int id, {
    bool runCallbacks = true,
  }) async {
    B? object = box.get(id);

    if (object != null) {
      object.toPermanentlyDeleted();
      await box.putAsync(object);
    }

    if (runCallbacks) afterCommit(id);
    return null;
  }
}
