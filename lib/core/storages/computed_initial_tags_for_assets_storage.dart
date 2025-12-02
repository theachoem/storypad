import 'package:storypad/core/storages/base_object_storages/bool_storage.dart';

class ComputedInitialTagsForAssetsStorage extends BoolStorage {
  // Increase version to initialize can run again.
  // But this time should set updated_at to record as well so it will sync to other devices.
  @override
  int? get version => 2;
}
