import 'package:flutter/foundation.dart';
import 'package:storypad/core/services/error_reporting/adaptors/base_error_reporting_adaptor.dart';

class NoneErrorReportingAdaptor extends BaseErrorReportingAdaptor {
  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false}) => Future.value();

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) => Future.value();
}
