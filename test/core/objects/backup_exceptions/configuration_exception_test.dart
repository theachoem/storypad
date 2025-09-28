import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

void main() {
  group('ConfigurationException', () {
    test('creates with correct properties', () {
      const exception = ConfigurationException(
        'Config error',
        context: 'app_setup',
      );

      expect(exception.message, equals('Config error'));
      expect(exception.context, equals('app_setup'));
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Configuration error. Please restart the app or contact support.'));
    });

    test('creates with minimal properties', () {
      const exception = ConfigurationException('Config error');

      expect(exception.message, equals('Config error'));
      expect(exception.context, isNull);
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Configuration error. Please restart the app or contact support.'));
    });

    test('is not retryable by default', () {
      const exception = ConfigurationException('Config error');
      expect(exception.isRetryable, isFalse);
    });

    test('can be made retryable by overriding default', () {
      const exception = ConfigurationException(
        'Config error',
        isRetryable: true, // Override the default
      );
      expect(exception.isRetryable, isTrue);
    });

    test('toString works correctly', () {
      const exception = ConfigurationException(
        'Config error',
        context: 'test_setup',
      );
      expect(exception.toString(), equals('BackupException: Config error (test_setup)'));
    });

    test('toString works without context', () {
      const exception = ConfigurationException('Config error');
      expect(exception.toString(), equals('BackupException: Config error'));
    });
  });
}
