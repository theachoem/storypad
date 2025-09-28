import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

void main() {
  group('ServiceException', () {
    test('creates with correct properties for validation failed', () {
      const exception = ServiceException(
        'Validation failed',
        ServiceExceptionType.validationFailed,
        context: 'backup_validation',
      );

      expect(exception.message, equals('Validation failed'));
      expect(exception.type, equals(ServiceExceptionType.validationFailed));
      expect(exception.context, equals('backup_validation'));
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Backup data validation failed. Please contact support.'));
    });

    test('creates with correct properties for compression failed', () {
      const exception = ServiceException(
        'Compression failed',
        ServiceExceptionType.compressionFailed,
      );

      expect(exception.message, equals('Compression failed'));
      expect(exception.type, equals(ServiceExceptionType.compressionFailed));
      expect(exception.context, isNull);
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Failed to compress backup data. Please try again.'));
    });

    test('creates with correct properties for decompression failed', () {
      const exception = ServiceException(
        'Decompression failed',
        ServiceExceptionType.decompressionFailed,
        context: 'restore_process',
      );

      expect(exception.message, equals('Decompression failed'));
      expect(exception.type, equals(ServiceExceptionType.decompressionFailed));
      expect(exception.context, equals('restore_process'));
      expect(exception.isRetryable, isFalse);
      expect(
          exception.userFriendlyMessage, equals('Failed to decompress backup data. The backup file may be corrupted.'));
    });

    test('creates with correct properties for data corrupted', () {
      const exception = ServiceException(
        'Data corrupted',
        ServiceExceptionType.dataCorrupted,
        context: 'backup_file',
      );

      expect(exception.message, equals('Data corrupted'));
      expect(exception.type, equals(ServiceExceptionType.dataCorrupted));
      expect(exception.context, equals('backup_file'));
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Backup data is corrupted and cannot be restored.'));
    });

    test('creates with correct properties for unexpected error', () {
      const exception = ServiceException(
        'Unexpected error',
        ServiceExceptionType.unexpectedError,
      );

      expect(exception.message, equals('Unexpected error'));
      expect(exception.type, equals(ServiceExceptionType.unexpectedError));
      expect(exception.context, isNull);
      expect(exception.isRetryable, isFalse);
      expect(
          exception.userFriendlyMessage, equals('An unexpected error occurred. Please try again or contact support.'));
    });

    test('is not retryable by default', () {
      const exception = ServiceException(
        'Service error',
        ServiceExceptionType.validationFailed,
      );
      expect(exception.isRetryable, isFalse);
    });

    test('can be made retryable by overriding default', () {
      const exception = ServiceException(
        'Service error',
        ServiceExceptionType.validationFailed,
        isRetryable: true, // Override the default
      );
      expect(exception.isRetryable, isTrue);
    });

    test('toString includes service context', () {
      const exception = ServiceException(
        'Validation failed',
        ServiceExceptionType.validationFailed,
        context: 'backup_service',
      );
      expect(exception.toString(), equals('BackupException: Validation failed (backup_service)'));
    });

    test('toString works without context', () {
      const exception = ServiceException(
        'Compression failed',
        ServiceExceptionType.compressionFailed,
      );
      expect(exception.toString(), equals('BackupException: Compression failed'));
    });

    group('ServiceExceptionType enum', () {
      test('has all expected values', () {
        expect(ServiceExceptionType.values, hasLength(5));
        expect(ServiceExceptionType.values, contains(ServiceExceptionType.validationFailed));
        expect(ServiceExceptionType.values, contains(ServiceExceptionType.compressionFailed));
        expect(ServiceExceptionType.values, contains(ServiceExceptionType.decompressionFailed));
        expect(ServiceExceptionType.values, contains(ServiceExceptionType.dataCorrupted));
        expect(ServiceExceptionType.values, contains(ServiceExceptionType.unexpectedError));
      });
    });
  });
}
