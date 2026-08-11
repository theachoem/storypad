import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

void main() {
  group('QuotaException', () {
    test('creates with correct properties for storage quota exceeded', () {
      const exception = QuotaException(
        'Storage full',
        QuotaExceptionType.storageQuotaExceeded,
        context: 'upload_backup',
        serviceType: BackupServiceType.google_drive,
      );

      expect(exception.message, equals('Storage full'));
      expect(exception.type, equals(QuotaExceptionType.storageQuotaExceeded));
      expect(exception.context, equals('upload_backup'));
      expect(exception.isRetryable, isFalse);
      expect(
        exception.userFriendlyMessage,
        equals('Google Drive storage is full. Please free up space or upgrade your storage plan.'),
      );
    });

    test('userFriendlyMessage names the actual provider, not always Google Drive', () {
      const exception = QuotaException(
        'Storage full',
        QuotaExceptionType.storageQuotaExceeded,
        serviceType: BackupServiceType.nextcloud,
      );

      expect(
        exception.userFriendlyMessage,
        equals('Nextcloud storage is full. Please free up space or upgrade your storage plan.'),
      );
    });

    test('userFriendlyMessage falls back to a neutral provider name when serviceType is unset', () {
      const exception = QuotaException(
        'Storage full',
        QuotaExceptionType.storageQuotaExceeded,
      );

      expect(
        exception.userFriendlyMessage,
        equals('Cloud storage is full. Please free up space or upgrade your storage plan.'),
      );
    });

    test('creates with correct properties for rate limit exceeded', () {
      const exception = QuotaException(
        'Rate limit exceeded',
        QuotaExceptionType.rateLimitExceeded,
      );

      expect(exception.message, equals('Rate limit exceeded'));
      expect(exception.type, equals(QuotaExceptionType.rateLimitExceeded));
      expect(exception.context, isNull);
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Too many requests. Please wait a moment before trying again.'));
    });

    test('creates with correct properties for daily limit exceeded', () {
      const exception = QuotaException(
        'Daily limit exceeded',
        QuotaExceptionType.dailyLimitExceeded,
        context: 'api_calls',
      );

      expect(exception.message, equals('Daily limit exceeded'));
      expect(exception.type, equals(QuotaExceptionType.dailyLimitExceeded));
      expect(exception.context, equals('api_calls'));
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Daily API limit reached. Please try again tomorrow.'));
    });

    test('is not retryable by default', () {
      const exception = QuotaException(
        'Quota exceeded',
        QuotaExceptionType.storageQuotaExceeded,
      );
      expect(exception.isRetryable, isFalse);
    });

    test('can be made retryable by overriding default', () {
      const exception = QuotaException(
        'Quota exceeded',
        QuotaExceptionType.storageQuotaExceeded,
        isRetryable: true, // Override the default
      );
      expect(exception.isRetryable, isTrue);
    });

    test('toString includes quota type context', () {
      const exception = QuotaException(
        'Storage full',
        QuotaExceptionType.storageQuotaExceeded,
        context: 'backup_upload',
      );
      expect(exception.toString(), equals('BackupException: Storage full (backup_upload)'));
    });

    test('toString works without context', () {
      const exception = QuotaException(
        'Rate limit exceeded',
        QuotaExceptionType.rateLimitExceeded,
      );
      expect(exception.toString(), equals('BackupException: Rate limit exceeded'));
    });

    group('QuotaExceptionType enum', () {
      test('has all expected values', () {
        expect(QuotaExceptionType.values, hasLength(3));
        expect(QuotaExceptionType.values, contains(QuotaExceptionType.storageQuotaExceeded));
        expect(QuotaExceptionType.values, contains(QuotaExceptionType.rateLimitExceeded));
        expect(QuotaExceptionType.values, contains(QuotaExceptionType.dailyLimitExceeded));
      });
    });
  });
}
