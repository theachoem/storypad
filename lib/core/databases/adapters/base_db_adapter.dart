import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';

abstract class BaseDbAdapter<T extends BaseDbModel> {
  final Map<int, List<FutureOr<void> Function(T?)>> _listeners = {};
  final List<FutureOr<void> Function()> _globalListeners = [];

  String get tableName;

  /// Returns a map where each key is a year (as an integer) and the value is the
  /// last updated timestamp (`DateTime?`) for records in that year.
  ///
  /// The [fromThisDeviceOnly] parameter, if true, restricts the results to records
  /// that were last updated from the current device only. If false or null, results
  /// include updates from all devices.
  ///
  /// This method is used in the backup flow to determine which records have been
  /// updated in each year, and to help identify which records need to be backed up
  /// or synchronized based on their last update time.
  Future<Map<int, DateTime?>> getLastUpdatedAtByYear({bool? fromThisDeviceOnly});
  Future<T?> find(int id, {bool returnDeleted = false});

  Future<int> count({
    Map<String, dynamic>? filters,
    required String? debugSource,
  });

  Future<CollectionDbModel<T>?> where({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? options,
    bool returnDeleted = false,
  });

  Future<T?> touch(
    T record, {
    bool runCallbacks = true,
  });

  Future<T?> set(
    T record, {
    bool runCallbacks = true,
  });

  Future<void> setAll(
    List<T> records, {
    bool runCallbacks = true,
  });

  Future<T?> update(
    T record, {
    bool runCallbacks = true,
  });

  Future<T?> create(
    T record, {
    bool runCallbacks = true,
  });

  Future<T?> delete(
    int id, {
    bool softDelete = true,
    bool runCallbacks = true,
    DateTime? deletedAt,
  });

  bool hasDeleted(int id);

  T modelFromJson(Map<String, dynamic> json);

  Future<void> afterCommit([int? id, T? model]) async {
    debugPrint("BaseDbAdapter#afterCommit ${model?.id}");

    for (FutureOr<void> Function() globalCallback in _globalListeners) {
      await globalCallback();
    }

    for (FutureOr<void> Function(T?) callback in _listeners[id] ?? []) {
      await callback(model);
    }
  }

  void addGlobalListener(
    Future<void> Function() callback,
  ) {
    _globalListeners.add(callback);
  }

  void removeGlobalListener(
    void Function() callback,
  ) {
    _globalListeners.remove(callback);
  }

  void addListener({
    required int recordId,
    required void Function(T?) callback,
  }) {
    _listeners[recordId] ??= [];
    _listeners[recordId]?.add(callback);
  }

  void removeListener({
    required int recordId,
    required void Function(T?) callback,
  }) {
    _listeners[recordId] ??= [];
    _listeners[recordId]?.remove(callback);
  }
}
