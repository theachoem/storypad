import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';

abstract class BaseStorage<T> {
  int? get version => null;
  String get key => version != null ? "$version-$runtimeType" : runtimeType.toString();
  Future<BaseStorageAdapter<T>> get adapter;

  Future<T?> read() async {
    return await (await adapter).read(key: key);
  }

  Future<void> write(T? value) async {
    if (value == null) return remove();
    await (await adapter).write(key: key, value: value);
  }

  Future<void> remove() async {
    await (await adapter).remove(key: key);
  }
}
