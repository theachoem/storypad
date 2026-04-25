import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/utils/firebase_platform_support.dart';

class FirebaseCrashlyticsInitializer {
  static void call() {
    _listenToErrors();
    _listenToNonFlutterErrors();
  }

  /// Returns true if the error is caused by a network issue outside our control,
  /// e.g. font downloads failing when the user has no internet access.
  static bool _isIgnorable(Object error) {
    final message = error.toString();
    return message.contains('fonts.gstatic.com') &&
        message.contains('SocketException');
  }

  static void _listenToErrors() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isIgnorable(details.exception)) return;
      if (!FirebasePlatformSupport.isSupported) {
        FlutterError.presentError(details);
        return;
      }

      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
  }

  static void _listenToNonFlutterErrors() {
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_isIgnorable(error)) return true;
      if (!FirebasePlatformSupport.isSupported) {
        debugPrint(error.toString());
        debugPrintStack(stackTrace: stack);
        return true;
      }

      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
