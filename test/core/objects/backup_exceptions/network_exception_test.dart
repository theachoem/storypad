import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

void main() {
  group('NetworkException', () {
    test('creates with correct properties', () {
      const exception = NetworkException(
        'Network error',
        context: 'test_operation',
        isRetryable: true,
      );

      expect(exception.message, equals('Network error'));
      expect(exception.context, equals('test_operation'));
      expect(exception.isRetryable, isTrue);
      expect(exception.userFriendlyMessage,
          equals('Network connection error. Please check your internet connection and try again.'));
    });

    test('is retryable by default', () {
      const exception = NetworkException('Network error');
      expect(exception.isRetryable, isTrue);
    });

    test('has default context as null', () {
      const exception = NetworkException('Network error');
      expect(exception.context, isNull);
    });

    test('toString includes context when provided', () {
      const exception = NetworkException(
        'Network error',
        context: 'test_context',
      );
      expect(exception.toString(), equals('BackupException: Network error (test_context)'));
    });

    test('toString excludes context when not provided', () {
      const exception = NetworkException('Network error');
      expect(exception.toString(), equals('BackupException: Network error'));
    });
  });
}
