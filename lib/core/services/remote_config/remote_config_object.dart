part of 'remote_config_service.dart';

enum _RemoteConfigValueType { boolean, string, int, double, json }

class _RemoteConfigObject<T> {
  final String key;
  final _RemoteConfigValueType type;
  final T defaultValue;

  const _RemoteConfigObject(
    this.key,
    this.type,
    this.defaultValue,
  );

  T get() {
    dynamic value;

    switch (type) {
      case _RemoteConfigValueType.boolean:
        value = RemoteConfigService.instance.remoteConfig.getBool(key) as T;
        break;
      case _RemoteConfigValueType.string:
        value = RemoteConfigService.instance.remoteConfig.getString(key) as T;
        break;
      case _RemoteConfigValueType.double:
        value = RemoteConfigService.instance.remoteConfig.getDouble(key) as T;
        break;
      case _RemoteConfigValueType.int:
        value = RemoteConfigService.instance.remoteConfig.getInt(key) as T;
        break;
      case _RemoteConfigValueType.json:
        String result = RemoteConfigService.instance.remoteConfig.getString(key);

        if (result.trim().isEmpty) {
          debugPrint('🐛 [firebase/remote_config] Either $key is not set in Firebase or wrong content type.');
          break;
        }

        try {
          dynamic json = jsonDecode(result);
          value = json;
        } on FormatException catch (e) {
          debugPrint("$runtimeType#get() decode JSON failed $e");
          if (!kIsWeb) {
            FirebaseCrashlytics.instance.recordError(e, StackTrace.fromString(e.message));
          }
        }

        break;
    }

    if (value is T) return value;
    return defaultValue;
  }
}
