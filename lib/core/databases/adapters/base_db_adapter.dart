import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';

abstract class BaseDbAdapter<T extends BaseDbModel> {
  final Map<int, List<FutureOr<void> Function(T?)>> _listeners = {};
  final List<FutureOr<void> Function()> _globalListeners = [];

  String get tableName;

  Future<DateTime?> getLastUpdatedAt({bool? fromThisDeviceOnly});
  Future<T?> find(int id, {bool returnDeleted = false});

  Future<int> count({Map<String, dynamic>? filters});
  Future<CollectionDbModel<T>?> where({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? options,
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
    bool runCallbacks = true,
  });

  bool hasDeleted(int id);

  T modelFromJson(Map<String, dynamic> json);

  Future<void> afterCommit([T? model]) async {
    debugPrint("BaseDbAdapter#afterCommit ${model?.id}");

    for (FutureOr<void> Function() globalCallback in _globalListeners) {
      await globalCallback();
    }

    for (FutureOr<void> Function(T?) callback in _listeners[model?.id] ?? []) {
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
