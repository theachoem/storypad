import 'package:storypad/core/objects/app_lock_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';

class AppLockStorage extends ObjectStorage<AppLockObject> {
  @override
  AppLockObject decode(Map<String, dynamic> json) {
    return AppLockObject.fromJson(json);
  }

  @override
  Map<String, dynamic> encode(AppLockObject object) {
    return object.toJson();
  }
}
