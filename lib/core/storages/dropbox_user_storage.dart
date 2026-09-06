import 'package:storypad/core/objects/dropbox_user_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';
import 'package:storypad/core/storages/storage_adapters/base_storage_adapter.dart';
import 'package:storypad/core/storages/storage_adapters/secure_storage_adaptor.dart';

class DropboxUserStorage extends ObjectStorage<DropboxUserObject> {
  @override
  Future<BaseStorageAdapter<String>> get adapter async => SecureStorageAdaptor();

  @override
  DropboxUserObject decode(Map<String, dynamic> json) => DropboxUserObject.fromJson(json);

  @override
  Map<String, dynamic> encode(DropboxUserObject object) => object.toJson();
}
