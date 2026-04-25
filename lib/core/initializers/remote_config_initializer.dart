import 'package:storypad/core/services/remote_config/remote_config_service.dart';

class RemoteConfigInitializer {
  static void call() {
    RemoteConfigService.instance.initialize();
  }
}
