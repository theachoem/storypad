// ignore_for_file: deprecated_member_use_from_same_package

import 'package:storypad/core/objects/app_lock_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';
import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';
import 'package:storypad/core/storages/storage_adapters/secure_storage_adaptor.dart';

class AppLockStorage extends ObjectStorage<AppLockObject> {
  @override
  Future<BaseStorageAdapter<String>> get adapter async => SecureStorageAdaptor();

  @override
  AppLockObject decode(Map<String, dynamic> json) => AppLockObject.fromJson(json);

  @override
  Map<String, dynamic> encode(AppLockObject object) => object.toJson();
}
