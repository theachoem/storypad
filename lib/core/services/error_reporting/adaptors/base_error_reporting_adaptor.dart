import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/services/error_reporting/adaptors/firebase_crashlytics_adaptor.dart';
import 'package:storypad/core/services/error_reporting/adaptors/none_error_reporting_adaptor.dart';

abstract class BaseErrorReportingAdaptor {
  static BaseErrorReportingAdaptor create() {
    return (!kIsWeb && Platform.isLinux) ? NoneErrorReportingAdaptor() : FirebaseCrashlyticsAdaptor();
  }

  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false});
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);
}
