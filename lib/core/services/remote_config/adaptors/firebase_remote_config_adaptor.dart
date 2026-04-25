import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/services/remote_config/adaptors/base_remote_config_adaptor.dart';

class FirebaseRemoteConfigAdaptor extends BaseRemoteConfigAdaptor {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  @override
  Future<void> initialize(Map<String, dynamic> defaults) async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 5),
          minimumFetchInterval: kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 12),
        ),
      );
      await _remoteConfig.setDefaults(defaults);
      await _remoteConfig.fetchAndActivate();
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  @override
  String getString(String key, String defaultValue) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  bool getBool(String key, bool defaultValue) {
    try {
      return _remoteConfig.getBool(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  int getInt(String key, int defaultValue) {
    try {
      return _remoteConfig.getInt(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  double getDouble(String key, double defaultValue) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  String getJsonString(String key, String defaultValue) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  Stream<Set<String>> get onConfigUpdated {
    if (kIsWeb) return const Stream.empty();
    return _remoteConfig.onConfigUpdated.asyncMap((event) async {
      await _remoteConfig.activate();
      return event.updatedKeys;
    });
  }
}
