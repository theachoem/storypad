import 'package:storypad/core/services/remote_config/adaptors/http_remote_config_adaptor.dart';

abstract class BaseRemoteConfigAdaptor {
  static BaseRemoteConfigAdaptor create() => HttpRemoteConfigAdaptor();

  Future<void> initialize(Map<String, dynamic> defaults);
  String getString(String key, String defaultValue);
  bool getBool(String key, bool defaultValue);
  int getInt(String key, int defaultValue);
  double getDouble(String key, double defaultValue);
  String getJsonString(String key, String defaultValue);
  Stream<Set<String>> get onConfigUpdated;
}
