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
    final adaptor = kRemoteConfigAdaptor;
    dynamic value;

    switch (type) {
      case _RemoteConfigValueType.boolean:
        value = adaptor.getBool(key, defaultValue as bool);
        break;
      case _RemoteConfigValueType.string:
        value = adaptor.getString(key, defaultValue as String);
        break;
      case _RemoteConfigValueType.double:
        value = adaptor.getDouble(key, defaultValue as double);
        break;
      case _RemoteConfigValueType.int:
        value = adaptor.getInt(key, defaultValue as int);
        break;
      case _RemoteConfigValueType.json:
        final result = adaptor.getJsonString(key, '');

        if (result.trim().isEmpty) {
          debugPrint('🐛 [remote_config] Either $key is not set or wrong content type.');
          break;
        }

        try {
          value = jsonDecode(result);
        } on FormatException catch (e) {
          debugPrint("$runtimeType#get() decode JSON failed $e");
          kErrorReportingService.recordError(e, StackTrace.fromString(e.message));
        }

        break;
    }

    if (value is T) return value;
    return defaultValue;
  }
}
