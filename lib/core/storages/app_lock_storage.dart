// ignore_for_file: deprecated_member_use_from_same_package

import 'package:storypad/core/objects/app_lock_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';
import 'package:storypad/core/storages/base_object_storages/bool_storage.dart';
import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';
import 'package:storypad/core/storages/storage_adapters/secure_storage_adaptor.dart';
import 'package:storypad/core/storages/storage_adapters/share_preferences_storage_adapter.dart';

class AppLockStorage extends ObjectStorage<AppLockObject> {
  @override
  Future<BaseStorageAdapter<String>> get adapter async => SecureStorageAdaptor();

  @override
  AppLockObject decode(Map<String, dynamic> json) => AppLockObject.fromJson(json);

  @override
  Map<String, dynamic> encode(AppLockObject object) => object.toJson();

  @override
  Future<AppLockObject?> readObject() async {
    AppLockObject? data = await super.readObject();

    bool? deprecatedData1 = await _LocalAuthEnabledStorage().read();
    AppLockObject? deprecatedData2 = await _AppLockStorage().readObject();

    if (deprecatedData1 != null) {
      data = (data ?? AppLockObject.init()).copyWith(enabledBiometric: deprecatedData1);
      await _LocalAuthEnabledStorage().remove();
      await writeObject(data);
    }

    if (deprecatedData2 != null) {
      data = deprecatedData2;
      await _AppLockStorage().remove();
      await writeObject(data);
    }

    return data;
  }
}

@Deprecated('Will be removed soon.')
class _AppLockStorage extends ObjectStorage<AppLockObject> {
  @override
  Future<BaseStorageAdapter<String>> get adapter async => SharePreferencesStorageAdapter();

  @override
  AppLockObject decode(Map<String, dynamic> json) => AppLockObject.fromJson(json);

  @override
  Map<String, dynamic> encode(AppLockObject object) => object.toJson();

  @override
  String get key => 'AppLockStorage';
}

@Deprecated('Will be removed soon.')
class _LocalAuthEnabledStorage extends BoolStorage {
  @override
  String get key => 'LocalAuthEnabledStorage';
}
