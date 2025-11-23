import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

void main() {
  group('GoogleDriveCloudService', () {
    test('creates NetworkException with correct properties', () {
      const exception = NetworkException(
        'Connection failed',
        context: 'test_operation',
        isRetryable: true,
      );

      expect(exception.message, equals('Connection failed'));
      expect(exception.context, equals('test_operation'));
      expect(exception.isRetryable, isTrue);
      expect(
        exception.userFriendlyMessage,
        equals('Network connection error. Please check your internet connection and try again.'),
      );
    });

    test('creates AuthException for token expired', () {
      const exception = AuthException(
        'Token expired',
        AuthExceptionType.tokenExpired,
        context: 'auth_test',
      );

      expect(exception.message, equals('Token expired'));
      expect(exception.type, equals(AuthExceptionType.tokenExpired));
      expect(exception.context, equals('auth_test'));
      expect(exception.requiresReauth, isTrue);
      expect(exception.requiresSignOut, isFalse);
    });

    test('creates AuthException for token revoked', () {
      const exception = AuthException(
        'Token revoked',
        AuthExceptionType.tokenRevoked,
      );

      expect(exception.requiresSignOut, isTrue);
      expect(exception.requiresReauth, isFalse);
    });

    test('creates QuotaException for storage quota', () {
      const exception = QuotaException(
        'Storage full',
        QuotaExceptionType.storageQuotaExceeded,
      );

      expect(exception.type, equals(QuotaExceptionType.storageQuotaExceeded));
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, contains('Google Drive storage is full'));
    });

    test('creates FileOperationException for upload', () {
      const exception = FileOperationException(
        'Upload failed',
        FileOperationType.upload,
        context: 'backup.json',
      );

      expect(exception.operation, equals(FileOperationType.upload));
      expect(exception.isRetryable, isTrue);
      expect(exception.userFriendlyMessage, equals('Failed to upload backup. Please try again.'));
    });

    test('creates ServiceException for data corruption', () {
      const exception = ServiceException(
        'Data corrupted',
        ServiceExceptionType.dataCorrupted,
      );

      expect(exception.type, equals(ServiceExceptionType.dataCorrupted));
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, contains('corrupted'));
    });

    test('handles sign-in cancellation', () {
      // This would require mocking GoogleSignIn
      // For now, test the exception directly
      const exception = AuthException(
        'Sign-in was cancelled by user',
        AuthExceptionType.signInFailed,
      );

      expect(exception.type, equals(AuthExceptionType.signInFailed));
      expect(exception.userFriendlyMessage, contains('sign in'));
    });

    test('handles missing access token', () {
      const exception = AuthException(
        'Failed to obtain access token',
        AuthExceptionType.signInFailed,
      );

      expect(exception.type, equals(AuthExceptionType.signInFailed));
    });

    test('handles insufficient scopes', () {
      const exception = AuthException(
        'Insufficient scopes granted',
        AuthExceptionType.insufficientScopes,
      );

      expect(exception.requiresScopeRequest, isTrue);
      expect(exception.userFriendlyMessage, contains('Additional permissions'));
    });

    test('handles common error scenarios', () {
      // Test network timeout
      expect(
        () => throw const NetworkException('Request timeout'),
        throwsA(isA<NetworkException>().having((e) => e.isRetryable, 'isRetryable', isTrue)),
      );

      // Test token expiration during operation
      expect(
        () => throw const AuthException('Token expired', AuthExceptionType.tokenExpired),
        throwsA(isA<AuthException>().having((e) => e.requiresReauth, 'requiresReauth', isTrue)),
      );

      // Test Google Drive storage full
      expect(
        () => throw const QuotaException('Storage quota exceeded', QuotaExceptionType.storageQuotaExceeded),
        throwsA(isA<QuotaException>().having((e) => e.userFriendlyMessage, 'message', contains('storage is full'))),
      );

      // Test file upload failure
      expect(
        () => throw const FileOperationException('Upload failed', FileOperationType.upload),
        throwsA(isA<FileOperationException>().having((e) => e.isRetryable, 'isRetryable', isTrue)),
      );

      // Test backup data corruption
      expect(
        () => throw const ServiceException('Data corrupted', ServiceExceptionType.dataCorrupted),
        throwsA(isA<ServiceException>().having((e) => e.userFriendlyMessage, 'message', contains('corrupted'))),
      );
    });

    test('provides appropriate user messages for different scenarios', () {
      const networkException = NetworkException('Connection failed');
      expect(
        networkException.userFriendlyMessage,
        equals('Network connection error. Please check your internet connection and try again.'),
      );

      const authException = AuthException('Token expired', AuthExceptionType.tokenExpired);
      expect(authException.userFriendlyMessage, equals('Your session has expired. Please sign in again.'));

      const quotaException = QuotaException('Storage full', QuotaExceptionType.storageQuotaExceeded);
      expect(
        quotaException.userFriendlyMessage,
        equals('Google Drive storage is full. Please free up space or upgrade your storage plan.'),
      );

      const fileException = FileOperationException('Upload failed', FileOperationType.upload);
      expect(fileException.userFriendlyMessage, equals('Failed to upload backup. Please try again.'));

      const serviceException = ServiceException('Validation failed', ServiceExceptionType.validationFailed);
      expect(serviceException.userFriendlyMessage, equals('Backup data validation failed. Please contact support.'));
    });
  });
}
