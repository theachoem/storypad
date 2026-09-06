import 'package:storypad/core/objects/icloud_user_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';
import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';
import 'package:storypad/core/storages/storage_adapters/secure_storage_adaptor.dart';

class ICloudUserStorage extends ObjectStorage<ICloudUserObject> {
  @override
  Future<BaseStorageAdapter<String>> get adapter async => SecureStorageAdaptor();

  @override
  ICloudUserObject decode(Map<String, dynamic> json) => ICloudUserObject.fromJson(json);

  @override
  Map<String, dynamic> encode(ICloudUserObject object) => object.toJson();
}
