import 'package:storypad/core/services/remote_config/remote_config_service.dart';

class FirebaseRemoteConfigInitializer {
  static Future<void> call() async {
    await RemoteConfigService.instance.initialize();
  }
}
