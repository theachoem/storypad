import 'package:storypad/core/objects/app_lock_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';
import 'package:storypad/core/storages/base_object_storages/bool_storage.dart';

class AppLockStorage extends ObjectStorage<AppLockObject> {
  @override
  AppLockObject decode(Map<String, dynamic> json) {
    return AppLockObject.fromJson(json);
  }

  @override
  Map<String, dynamic> encode(AppLockObject object) {
    return object.toJson();
  }

  @override
  Future<AppLockObject?> readObject() async {
    AppLockObject? data = await super.readObject();

    // TODO: remove this after a while.
    // ignore: deprecated_member_use_from_same_package
    bool? deprecatedData = await LocalAuthEnabledStorage().read();

    if (deprecatedData != null) {
      data = (data ?? AppLockObject.init()).copyWith(enabledBiometric: deprecatedData);

      // ignore: deprecated_member_use_from_same_package
      LocalAuthEnabledStorage().remove();
    }

    return data;
  }
}

@Deprecated('Will be removed soon.')
class LocalAuthEnabledStorage extends BoolStorage {}
