import 'package:storypad/core/objects/cloud_service_user.dart';

class WebDevUserObject extends CloudServiceUser {
  final String serverUrl;
  final String password;

  WebDevUserObject({
    required this.serverUrl,
    required this.password,
  });

  String get username => "storypad";

  @override
  String? get displayName => "storypad";

  @override
  String get identifier => "storypad";

  @override
  String? get photoUrl => null;
}
