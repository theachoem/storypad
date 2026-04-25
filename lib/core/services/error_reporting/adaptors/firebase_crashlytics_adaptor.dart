import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/services/error_reporting/adaptors/base_error_reporting_adaptor.dart';

class FirebaseCrashlyticsAdaptor extends BaseErrorReportingAdaptor {
  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false}) {
    if (kIsWeb) return Future.value();
    return FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) {
    if (kIsWeb) return Future.value();
    return FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  }
}
