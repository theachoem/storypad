import 'package:storypad/core/services/remote_config/adaptors/base_remote_config_adaptor.dart';

class NoneRemoteConfigAdaptor extends BaseRemoteConfigAdaptor {
  @override
  Future<void> initialize(Map<String, dynamic> defaults) => Future.value();

  @override
  String getString(String key, String defaultValue) => defaultValue;

  @override
  bool getBool(String key, bool defaultValue) => defaultValue;

  @override
  int getInt(String key, int defaultValue) => defaultValue;

  @override
  double getDouble(String key, double defaultValue) => defaultValue;

  @override
  String getJsonString(String key, String defaultValue) => defaultValue;

  @override
  Stream<Set<String>> get onConfigUpdated => const Stream.empty();
}
