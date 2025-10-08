import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';

void main() {
  group('AuthException', () {
    test('creates with correct properties for token expired', () {
      const exception = AuthException(
        'Token expired',
        AuthExceptionType.tokenExpired,
        context: 'test_auth',
      );

      expect(exception.message, equals('Token expired'));
      expect(exception.type, equals(AuthExceptionType.tokenExpired));
      expect(exception.context, equals('test_auth'));
      expect(exception.isRetryable, isFalse);
      expect(exception.userFriendlyMessage, equals('Your session has expired. Please sign in again.'));
      expect(exception.requiresReauth, isTrue);
      expect(exception.requiresSignOut, isFalse);
      expect(exception.requiresScopeRequest, isFalse);
    });

    test('creates with correct properties for token revoked', () {
      const exception = AuthException(
        'Token revoked',
        AuthExceptionType.tokenRevoked,
      );

      expect(exception.message, equals('Token revoked'));
      expect(exception.type, equals(AuthExceptionType.tokenRevoked));
      expect(exception.context, isNull);
      expect(exception.isRetryable, isFalse);
      expect(exception.requiresSignOut, isTrue);
      expect(exception.requiresReauth, isFalse);
      expect(exception.requiresScopeRequest, isFalse);
      expect(
        exception.userFriendlyMessage,
        equals('Access has been revoked. Please sign in again to continue using backup.'),
      );
    });

    test('creates with correct properties for insufficient scopes', () {
      const exception = AuthException(
        'Insufficient scopes',
        AuthExceptionType.insufficientScopes,
      );

      expect(exception.message, equals('Insufficient scopes'));
      expect(exception.type, equals(AuthExceptionType.insufficientScopes));
      expect(exception.requiresScopeRequest, isTrue);
      expect(exception.requiresReauth, isFalse);
      expect(exception.requiresSignOut, isFalse);
      expect(exception.userFriendlyMessage, equals('Additional permissions are required for backup functionality.'));
    });

    test('creates with correct properties for sign in required', () {
      const exception = AuthException(
        'Sign in required',
        AuthExceptionType.signInRequired,
      );

      expect(exception.message, equals('Sign in required'));
      expect(exception.type, equals(AuthExceptionType.signInRequired));
      expect(exception.requiresReauth, isTrue);
      expect(exception.requiresSignOut, isFalse);
      expect(exception.requiresScopeRequest, isFalse);
      expect(exception.userFriendlyMessage, equals('Please sign in to Google Drive to use backup features.'));
    });

    test('creates with correct properties for sign in failed', () {
      const exception = AuthException(
        'Sign in failed',
        AuthExceptionType.signInFailed,
      );

      expect(exception.message, equals('Sign in failed'));
      expect(exception.type, equals(AuthExceptionType.signInFailed));
      expect(exception.requiresReauth, isFalse);
      expect(exception.requiresSignOut, isFalse);
      expect(exception.requiresScopeRequest, isFalse);
      expect(exception.userFriendlyMessage, equals('Failed to sign in to Google Drive. Please try again.'));
    });

    test('is not retryable by default', () {
      const exception = AuthException(
        'Auth error',
        AuthExceptionType.tokenExpired,
      );
      expect(exception.isRetryable, isFalse);
    });

    test('toString includes type information', () {
      const exception = AuthException(
        'Token expired',
        AuthExceptionType.tokenExpired,
        context: 'test_auth',
      );
      expect(exception.toString(), equals('BackupException: Token expired (test_auth)'));
    });

    group('AuthExceptionType enum', () {
      test('has all expected values', () {
        expect(AuthExceptionType.values, hasLength(5));
        expect(AuthExceptionType.values, contains(AuthExceptionType.tokenExpired));
        expect(AuthExceptionType.values, contains(AuthExceptionType.tokenRevoked));
        expect(AuthExceptionType.values, contains(AuthExceptionType.insufficientScopes));
        expect(AuthExceptionType.values, contains(AuthExceptionType.signInRequired));
        expect(AuthExceptionType.values, contains(AuthExceptionType.signInFailed));
      });
    });
  });
}
