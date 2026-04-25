import 'package:flutter/foundation.dart';
import 'package:storypad/core/constants/app_constants.dart';

class CrashlyticsInitializer {
  static void call() {
    _listenToErrors();
    _listenToNonFlutterErrors();
  }

  /// Returns true if the error is caused by a network issue outside our control,
  /// e.g. font downloads failing when the user has no internet access.
  static bool _isIgnorable(Object error) {
    final message = error.toString();
    return message.contains('fonts.gstatic.com') && message.contains('SocketException');
  }

  static void _listenToErrors() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (_isIgnorable(details.exception)) return;
      kErrorReportingService.recordFlutterFatalError(details);
    };
  }

  static void _listenToNonFlutterErrors() {
    PlatformDispatcher.instance.onError = (error, stack) {
      if (_isIgnorable(error)) return true;
      kErrorReportingService.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
