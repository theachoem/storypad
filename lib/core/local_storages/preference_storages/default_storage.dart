import 'package:storypad/core/local_storages/preference_storages/base_storage.dart';
import 'package:storypad/core/local_storages/storage_adapters/base_storage_adapter.dart';
import 'package:storypad/core/local_storages/storage_adapters/share_preferences_storage_adapter.dart';

abstract class DefaultStorage<T> extends BaseStorage<T> {
  @override
  Future<BaseStorageAdapter<T>> get adapter async => SharePreferencesStorageAdapter<T>();
}
