import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

// Concrete implementation for testing the abstract BackupException
class TestBackupException extends BackupException {
  const TestBackupException(
    super.message, {
    super.context,
    super.isRetryable = false,
  });
}

void main() {
  group('BackupException', () {
    test('creates with correct properties', () {
      const exception = TestBackupException(
        'Test error',
        context: 'test_operation',
        isRetryable: true,
      );

      expect(exception.message, equals('Test error'));
      expect(exception.context, equals('test_operation'));
      expect(exception.isRetryable, isTrue);
      expect(exception.userFriendlyMessage, equals('Test error')); // Default implementation
    });

    test('creates with minimal properties', () {
      const exception = TestBackupException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.context, isNull);
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Test error'));
    });

    test('toString includes context when provided', () {
      const exception = TestBackupException(
        'Test error',
        context: 'test_context',
      );
      expect(exception.toString(), equals('BackupException: Test error (test_context)'));
    });

    test('toString excludes context when not provided', () {
      const exception = TestBackupException('Test error');
      expect(exception.toString(), equals('BackupException: Test error'));
    });

    test('userFriendlyMessage defaults to message', () {
      const exception = TestBackupException('Technical error message');
      expect(exception.userFriendlyMessage, equals('Technical error message'));
    });

    test('isRetryable defaults to false', () {
      const exception = TestBackupException('Test error');
      expect(exception.isRetryable, isFalse);
    });

    test('can be made retryable', () {
      const exception = TestBackupException(
        'Test error',
        isRetryable: true,
      );
      expect(exception.isRetryable, isTrue);
    });
  });
}
