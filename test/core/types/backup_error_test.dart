import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/types/backup_error.dart';

void main() {
  group('BackupError', () {
    group('factory constructors', () {
      test('creates authentication errors correctly', () {
        final signInFailed = BackupError.signInFailed('Details');
        expect(signInFailed.type, equals(BackupErrorType.authentication));
        expect(signInFailed.code, equals('SIGN_IN_FAILED'));
        expect(signInFailed.message, equals('Failed to sign in to Google Drive'));
        expect(signInFailed.details, equals('Details'));

        final signInCancelled = BackupError.signInCancelled();
        expect(signInCancelled.type, equals(BackupErrorType.authentication));
        expect(signInCancelled.code, equals('SIGN_IN_CANCELLED'));
        expect(signInCancelled.message, equals('Sign in was cancelled by user'));

        final insufficientPermissions = BackupError.insufficientPermissions();
        expect(insufficientPermissions.type, equals(BackupErrorType.authentication));
        expect(insufficientPermissions.code, equals('INSUFFICIENT_PERMISSIONS'));

        final tokenExpired = BackupError.tokenExpired();
        expect(tokenExpired.type, equals(BackupErrorType.authentication));
        expect(tokenExpired.code, equals('TOKEN_EXPIRED'));
      });

      test('creates network errors correctly', () {
        final networkError = BackupError.networkError('Connection failed');
        expect(networkError.type, equals(BackupErrorType.network));
        expect(networkError.code, equals('NETWORK_ERROR'));
        expect(networkError.details, equals('Connection failed'));

        final noInternet = BackupError.noInternet();
        expect(noInternet.type, equals(BackupErrorType.network));
        expect(noInternet.code, equals('NO_INTERNET'));

        final timeout = BackupError.timeout();
        expect(timeout.type, equals(BackupErrorType.network));
        expect(timeout.code, equals('TIMEOUT'));
      });

      test('creates Google Drive API errors correctly', () {
        final quotaExceeded = BackupError.quotaExceeded();
        expect(quotaExceeded.type, equals(BackupErrorType.googleDriveApi));
        expect(quotaExceeded.code, equals('QUOTA_EXCEEDED'));

        final rateLimitExceeded = BackupError.rateLimitExceeded();
        expect(rateLimitExceeded.type, equals(BackupErrorType.googleDriveApi));
        expect(rateLimitExceeded.code, equals('RATE_LIMIT_EXCEEDED'));

        final uploadFailed = BackupError.uploadFailed('Upload details');
        expect(uploadFailed.type, equals(BackupErrorType.googleDriveApi));
        expect(uploadFailed.code, equals('UPLOAD_FAILED'));

        final downloadFailed = BackupError.downloadFailed('Download details');  
        expect(downloadFailed.type, equals(BackupErrorType.googleDriveApi));
        expect(downloadFailed.code, equals('DOWNLOAD_FAILED'));

        final fileNotFound = BackupError.fileNotFound('test.json');
        expect(fileNotFound.type, equals(BackupErrorType.googleDriveApi));
        expect(fileNotFound.code, equals('FILE_NOT_FOUND'));
        expect(fileNotFound.details, equals('File: test.json'));
      });

      test('creates local storage errors correctly', () {
        final databaseError = BackupError.databaseError('DB failed');
        expect(databaseError.type, equals(BackupErrorType.localStorage));
        expect(databaseError.code, equals('DATABASE_ERROR'));

        final backupCorrupted = BackupError.backupCorrupted();
        expect(backupCorrupted.type, equals(BackupErrorType.localStorage));
        expect(backupCorrupted.code, equals('BACKUP_CORRUPTED'));
      });

      test('creates file system errors correctly', () {
        final fileReadError = BackupError.fileReadError('/path/to/file');
        expect(fileReadError.type, equals(BackupErrorType.fileSystem));
        expect(fileReadError.code, equals('FILE_READ_ERROR'));
        expect(fileReadError.details, equals('Path: /path/to/file'));

        final fileWriteError = BackupError.fileWriteError('/path/to/file');
        expect(fileWriteError.type, equals(BackupErrorType.fileSystem));
        expect(fileWriteError.code, equals('FILE_WRITE_ERROR'));

        final insufficientStorage = BackupError.insufficientStorage();
        expect(insufficientStorage.type, equals(BackupErrorType.fileSystem));
        expect(insufficientStorage.code, equals('INSUFFICIENT_STORAGE'));
      });

      test('creates serialization errors correctly', () {
        final serializationError = BackupError.serializationError('JSON error');
        expect(serializationError.type, equals(BackupErrorType.serialization));
        expect(serializationError.code, equals('SERIALIZATION_ERROR'));

        final deserializationError = BackupError.deserializationError('Parse error');
        expect(deserializationError.type, equals(BackupErrorType.serialization));
        expect(deserializationError.code, equals('DESERIALIZATION_ERROR'));
      });

      test('creates general errors correctly', () {
        final maxRetriesExceeded = BackupError.maxRetriesExceeded();
        expect(maxRetriesExceeded.type, equals(BackupErrorType.unknown));
        expect(maxRetriesExceeded.code, equals('MAX_RETRIES_EXCEEDED'));

        final exception = Exception('Test exception');
        final unknown = BackupError.unknown('Unknown error', exception);
        expect(unknown.type, equals(BackupErrorType.unknown));
        expect(unknown.code, equals('UNKNOWN_ERROR'));
        expect(unknown.message, equals('Unknown error'));
        expect(unknown.originalError, equals(exception));
      });
    });

    group('userFriendlyMessage', () {
      test('returns appropriate messages for authentication errors', () {
        expect(
          BackupError.signInCancelled().userFriendlyMessage,
          equals('Please sign in to Google Drive to sync your data.'),
        );

        expect(
          BackupError.insufficientPermissions().userFriendlyMessage,
          equals('Please grant Google Drive permissions to backup your stories.'),
        );

        expect(
          BackupError.tokenExpired().userFriendlyMessage,
          equals('Your Google Drive session has expired. Please sign in again.'),
        );

        expect(
          BackupError.signInFailed().userFriendlyMessage,
          equals('Authentication error. Please try signing in again.'),
        );
      });

      test('returns appropriate messages for network errors', () {
        expect(
          BackupError.noInternet().userFriendlyMessage,
          equals('No internet connection. Please check your network and try again.'),
        );

        expect(
          BackupError.timeout().userFriendlyMessage,
          equals('Connection timed out. Please try again.'),
        );

        expect(
          BackupError.networkError().userFriendlyMessage,
          equals('Network error. Please check your connection and try again.'),
        );
      });

      test('returns appropriate messages for API errors', () {
        expect(
          BackupError.quotaExceeded().userFriendlyMessage,
          equals('Your Google Drive storage is full. Please free up space and try again.'),
        );

        expect(
          BackupError.rateLimitExceeded().userFriendlyMessage,
          equals('Too many requests. Please wait a moment and try again.'),
        );

        expect(
          BackupError.fileNotFound('test.json').userFriendlyMessage,
          equals('Backup file not found on Google Drive.'),
        );

        expect(
          BackupError.uploadFailed().userFriendlyMessage,
          equals('Google Drive error. Please try again later.'),
        );
      });

      test('returns appropriate messages for storage errors', () {
        expect(
          BackupError.backupCorrupted().userFriendlyMessage,
          equals('The backup file is corrupted and cannot be restored.'),
        );

        expect(
          BackupError.databaseError().userFriendlyMessage,
          equals('Local storage error. Please restart the app and try again.'),
        );
      });

      test('returns appropriate messages for file system errors', () {
        expect(
          BackupError.insufficientStorage().userFriendlyMessage,
          equals('Not enough storage space on your device.'),
        );

        expect(
          BackupError.fileReadError('/path').userFriendlyMessage,
          equals('File system error. Please check your device storage.'),
        );
      });

      test('returns appropriate messages for serialization errors', () {
        expect(
          BackupError.serializationError().userFriendlyMessage,
          equals('Data format error. Please contact support if this persists.'),
        );

        expect(
          BackupError.deserializationError().userFriendlyMessage,
          equals('Data format error. Please contact support if this persists.'),
        );
      });

      test('returns original message for unknown errors', () {
        expect(
          BackupError.unknown('Custom error message').userFriendlyMessage,
          equals('Custom error message'),
        );
      });
    });

    group('equality and hashCode', () {
      test('equal errors have same hash code', () {
        final error1 = BackupError.signInFailed('Details');
        final error2 = BackupError.signInFailed('Details');
        
        expect(error1, equals(error2));
        expect(error1.hashCode, equals(error2.hashCode));
      });

      test('different errors are not equal', () {
        final error1 = BackupError.signInFailed('Details');
        final error2 = BackupError.signInCancelled();
        
        expect(error1, isNot(equals(error2)));
      });
    });

    group('toString', () {
      test('includes all relevant information', () {
        final error = BackupError.uploadFailed('Upload details');
        final str = error.toString();
        
        expect(str, contains('BackupError'));
        expect(str, contains('googleDriveApi'));
        expect(str, contains('UPLOAD_FAILED'));
        expect(str, contains('Failed to upload file to Google Drive'));
        expect(str, contains('Upload details'));
      });

      test('includes original error when present', () {
        final originalError = Exception('Original');
        final error = BackupError.unknown('Test', originalError);
        final str = error.toString();
        
        expect(str, contains('originalError: Exception: Original'));
      });
    });
  });
}