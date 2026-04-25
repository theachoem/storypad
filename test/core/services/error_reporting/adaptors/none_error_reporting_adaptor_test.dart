import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/error_reporting/adaptors/none_error_reporting_adaptor.dart';

void main() {
  late NoneErrorReportingAdaptor adaptor;

  setUp(() => adaptor = NoneErrorReportingAdaptor());

  group('NoneErrorReportingAdaptor', () {
    test('recordError completes without throwing', () async {
      await expectLater(
        adaptor.recordError(Exception('boom'), StackTrace.current),
        completes,
      );
    });

    test('recordError with fatal: true completes without throwing', () async {
      await expectLater(
        adaptor.recordError(Exception('fatal'), StackTrace.current, fatal: true),
        completes,
      );
    });

    test('recordFlutterFatalError completes without throwing', () async {
      final details = FlutterErrorDetails(exception: Exception('flutter error'));
      await expectLater(adaptor.recordFlutterFatalError(details), completes);
    });
  });
}
