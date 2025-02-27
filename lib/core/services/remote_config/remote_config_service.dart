import 'dart:async';
import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

part './remote_config_object.dart';

class RemoteConfigService {
  final List<_RemoteConfigObject> _registeredKeys = [
    communityUrl,
    localizationSupportUrl,
    policyPrivacyUrl,
    sourceCodeUrl,
  ];

  FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  static final instance = RemoteConfigService._();
  RemoteConfigService._();

  final Map<Type, void Function()> _listeners = {};
  void clearListeners(String key, void Function() callback) => _listeners.clear();
  void notifyListeners() {
    for (var callback in _listeners.values) {
      callback.call();
    }
  }

  void addListener(Type key, void Function() callback) {
    _listeners[key] = callback;
  }

  static const communityUrl = _RemoteConfigObject<String>(
    'COMMUNITY_URL',
    _RemoteConfigValueType.string,
    'https://www.reddit.com/r/StoryPad',
  );

  static const localizationSupportUrl = _RemoteConfigObject<String>(
    'LOCALIZATION_SUPPORT_URL',
    _RemoteConfigValueType.string,
    'https://github.com/theachoem/storypad/issues/257',
  );

  static const policyPrivacyUrl = _RemoteConfigObject<String>(
    'POLICY_PRIVACY_URL',
    _RemoteConfigValueType.string,
    'https://storypad.juniorise.com/privacy-policy/storypad',
  );

  static const sourceCodeUrl = _RemoteConfigObject<String>(
    'SOURCE_CODE_URL',
    _RemoteConfigValueType.string,
    'https://github.com/theachoem/storypad',
  );

  Future<void> initialize() async {
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 5),
        minimumFetchInterval: kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 12),
      ));

      await remoteConfig.setDefaults({
        for (final element in _registeredKeys)
          element.key: element.defaultValue is Map ? jsonEncode(element.defaultValue) : element.defaultValue,
      });

      await remoteConfig.fetchAndActivate();
      notifyListeners();
    } catch (error) {
      debugPrint(error.toString());
    }

    if (!kIsWeb) {
      remoteConfig.onConfigUpdated.listen((event) async {
        debugPrint(event.updatedKeys.toString());
        await remoteConfig.activate();
        notifyListeners();
      }, onError: (error) {
        debugPrint(error);
      });
    }
  }
}
