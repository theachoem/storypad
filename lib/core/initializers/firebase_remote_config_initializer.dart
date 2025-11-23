import 'package:storypad/core/services/remote_config/remote_config_service.dart';

class FirebaseRemoteConfigInitializer {
  static void call() {
    RemoteConfigService.instance.initialize();
  }
}
