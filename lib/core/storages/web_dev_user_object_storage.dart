import 'package:storypad/core/objects/web_dev_user_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';

class WebDevUserObjectStorage extends ObjectStorage<WebDevUserObject> {
  @override
  WebDevUserObject decode(Map<String, dynamic> json) => WebDevUserObject(
    serverUrl: json['serverUrl'] as String,
    password: json['password'] as String,
  );

  @override
  Map<String, dynamic> encode(WebDevUserObject object) => {
    'serverUrl': object.serverUrl,
    'password': object.password,
  };
}
