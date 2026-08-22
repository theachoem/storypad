import 'package:storypad/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/services/error_reporting/adaptors/firebase_crashlytics_adaptor.dart';
import 'package:storypad/core/services/error_reporting/adaptors/none_error_reporting_adaptor.dart';

abstract class BaseErrorReportingAdaptor {
  static BaseErrorReportingAdaptor create() {
    return kFirebaseAvailable ? FirebaseCrashlyticsAdaptor() : NoneErrorReportingAdaptor();
  }

  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false});
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);

  /// Breadcrumb log attached to the next crash/error report, not a report on
  /// its own — no-ops when the underlying backend is unavailable.
  Future<void> log(String message);
}
