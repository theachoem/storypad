import 'package:storypad/core/services/remote_config/remote_config_service.dart';

class FeatureFlags {
  FeatureFlags._();

  static bool relaxSound = RemoteConfigService.featureFlags.get()['relax_sounds'] == true;
  static bool template = RemoteConfigService.featureFlags.get()['templates'] == true;
}
