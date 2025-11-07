import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';

// This is just for example.
class BaseSqliteDbAdapter extends BaseDbAdapter {
  @override
  String get tableName => throw UnimplementedError();

  @override
  Future<BaseDbModel?> create(
    BaseDbModel record, {
    bool runCallbacks = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BaseDbModel?> delete(
    int id, {
    bool softDelete = true,
    bool runCallbacks = true,
    DateTime? deletedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BaseDbModel?> find(int id, {bool returnDeleted = false}) {
    throw UnimplementedError();
  }

  @override
  bool hasDeleted(int id) {
    throw UnimplementedError();
  }

  @override
  Future<BaseDbModel?> update(
    BaseDbModel record, {
    bool runCallbacks = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> count({Map<String, dynamic>? filters}) {
    throw UnimplementedError();
  }

  @override
  Future<CollectionDbModel<BaseDbModel>?> where({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? options,
    bool returnDeleted = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BaseDbModel?> touch(
    BaseDbModel record, {
    bool runCallbacks = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BaseDbModel?> set(
    BaseDbModel record, {
    bool runCallbacks = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly}) {
    throw UnimplementedError();
  }

  @override
  BaseDbModel modelFromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  Future<void> setAll(
    List<BaseDbModel> records, {
    bool runCallbacks = true,
  }) {
    throw UnimplementedError();
  }
}
