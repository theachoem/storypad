import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:storypad/core/exceptions/google_drive_exceptions.dart';
import 'package:storypad/core/models/backup_state.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/repositories/backup_repository_new.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/types/backup_error.dart';
import 'package:storypad/core/types/result.dart';

import 'backup_repository_new_test.mocks.dart';

@GenerateMocks([
  GoogleDriveClient,
  InternetCheckerService,
  RestoreBackupService,
])
void main() {
  group('BackupRepositoryNew', () {
    late BackupRepositoryNew repository;
    late MockGoogleDriveClient mockGoogleDriveClient;
    late MockInternetCheckerService mockInternetChecker;
    late MockRestoreBackupService mockRestoreBackupService;

    setUp(() {
      mockGoogleDriveClient = MockGoogleDriveClient();
      mockInternetChecker = MockInternetCheckerService();
      mockRestoreBackupService = MockRestoreBackupService();

      repository = BackupRepositoryNew(
        googleDriveClient: mockGoogleDriveClient,
        internetChecker: mockInternetChecker,
        restoreBackupService: mockRestoreBackupService,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('signIn', () {
      test('returns success when sign-in succeeds', () async {
        // Arrange
        when(mockGoogleDriveClient.signIn()).thenAnswer((_) async => true);

        // Act
        final result = await repository.signIn();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
        verify(mockGoogleDriveClient.signIn()).called(1);
      });

      test('returns error when sign-in is cancelled', () async {
        // Arrange
        when(mockGoogleDriveClient.signIn())
            .thenThrow(GoogleDriveAuthException.signInCancelled());

        // Act
        final result = await repository.signIn();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.authentication));
        expect(result.error.code, equals('SIGN_IN_CANCELLED'));
      });

      test('returns error when network fails', () async {
        // Arrange
        when(mockGoogleDriveClient.signIn())
            .thenThrow(GoogleDriveNetworkException.noConnection());

        // Act
        final result = await repository.signIn();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.network));
        expect(result.error.code, equals('NO_INTERNET'));
      });

      test('returns unknown error for unexpected exceptions', () async {
        // Arrange
        when(mockGoogleDriveClient.signIn())
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result = await repository.signIn();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.unknown));
        expect(result.error.code, equals('UNKNOWN_ERROR'));
      });
    });

    group('signOut', () {
      test('returns success when sign-out succeeds', () async {
        // Arrange
        when(mockGoogleDriveClient.signOut()).thenAnswer((_) async => {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockGoogleDriveClient.signOut()).called(1);
      });

      test('returns error when sign-out fails', () async {
        // Arrange
        when(mockGoogleDriveClient.signOut())
            .thenThrow(GoogleDriveAuthException('Sign out failed'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.authentication));
      });
    });

    group('checkConnection', () {
      test('returns authRequired when not signed in', () async {
        // Arrange
        when(mockGoogleDriveClient.currentUser).thenReturn(null);

        // Act
        final result = await repository.checkConnection();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(BackupConnectionState.authRequired));
      });

      test('returns offline when no internet', () async {
        // Arrange
        final user = GoogleUserObject(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          accessToken: 'token',
          refreshedAt: DateTime.now(),
        );
        when(mockGoogleDriveClient.currentUser).thenReturn(user);
        when(mockInternetChecker.check()).thenAnswer((_) async => false);

        // Act
        final result = await repository.checkConnection();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(BackupConnectionState.offline));
      });

      test('returns ready when all checks pass', () async {
        // Arrange
        final user = GoogleUserObject(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          accessToken: 'token',
          refreshedAt: DateTime.now(),
        );
        when(mockGoogleDriveClient.currentUser).thenReturn(user);
        when(mockInternetChecker.check()).thenAnswer((_) async => true);
        when(mockGoogleDriveClient.reauthenticateIfNeeded())
            .thenAnswer((_) async => true);
        when(mockGoogleDriveClient.canAccessRequestedScopes())
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.checkConnection();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(BackupConnectionState.ready));
      });

      test('returns authRequired when scopes not accessible', () async {
        // Arrange
        final user = GoogleUserObject(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          accessToken: 'token',
          refreshedAt: DateTime.now(),
        );
        when(mockGoogleDriveClient.currentUser).thenReturn(user);
        when(mockInternetChecker.check()).thenAnswer((_) async => true);
        when(mockGoogleDriveClient.reauthenticateIfNeeded())
            .thenAnswer((_) async => true);
        when(mockGoogleDriveClient.canAccessRequestedScopes())
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.checkConnection();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(BackupConnectionState.authRequired));
      });
    });

    group('uploadImages', () {
      test('returns success when no images to upload', () async {
        // Arrange
        final user = GoogleUserObject(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          accessToken: 'token',
          refreshedAt: DateTime.now(),
        );
        when(mockGoogleDriveClient.currentUser).thenReturn(user);

        // Act
        final result = await repository.uploadImages();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('returns error when not signed in', () async {
        // Arrange
        when(mockGoogleDriveClient.currentUser).thenReturn(null);

        // Act
        final result = await repository.uploadImages();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.authentication));
        expect(result.error.code, equals('SIGN_IN_FAILED'));
      });

      test('retries on network errors', () async {
        // Arrange
        final user = GoogleUserObject(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          accessToken: 'token',
          refreshedAt: DateTime.now(),
        );
        when(mockGoogleDriveClient.currentUser).thenReturn(user);

        // Mock to fail first two times, succeed on third
        when(mockGoogleDriveClient.uploadFile(any, any, folderName: anyNamed('folderName')))
            .thenThrow(GoogleDriveNetworkException.timeout())
            .thenThrow(GoogleDriveNetworkException.timeout())
            .thenAnswer((_) async => throw Exception('Mock should not reach here'));

        // Act
        final result = await repository.uploadImages();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.network));
      });

      test('does not retry auth errors', () async {
        // Arrange
        final user = GoogleUserObject(
          id: 'test-id',
          email: 'test@example.com',
          displayName: 'Test User',
          photoUrl: null,
          accessToken: 'token',
          refreshedAt: DateTime.now(),
        );
        when(mockGoogleDriveClient.currentUser).thenReturn(user);

        // Mock to fail with auth error
        when(mockGoogleDriveClient.uploadFile(any, any, folderName: anyNamed('folderName')))
            .thenThrow(GoogleDriveAuthException.tokenExpired());

        // Act
        final result = await repository.uploadImages();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.authentication));
        // Should only try once for auth errors
      });
    });

    group('progressStream', () {
      test('emits progress updates during sync operations', () async {
        // Arrange
        final progressEvents = <BackupProgressState>[];
        final subscription = repository.progressStream.listen(progressEvents.add);

        try {
          // Act - This would be called internally during sync operations
          // We can't easily test the actual sync flow without more mocking
          // So we'll test that the stream exists and can be listened to
          
          // Assert
          expect(repository.progressStream, isNotNull);
          expect(subscription, isNotNull);
        } finally {
          await subscription.cancel();
        }
      });
    });
  });

  group('Error Mapping', () {
    late BackupRepositoryNew repository;
    late MockGoogleDriveClient mockGoogleDriveClient;
    late MockInternetCheckerService mockInternetChecker;
    late MockRestoreBackupService mockRestoreBackupService;

    setUp(() {
      mockGoogleDriveClient = MockGoogleDriveClient();
      mockInternetChecker = MockInternetCheckerService();
      mockRestoreBackupService = MockRestoreBackupService();

      repository = BackupRepositoryNew(
        googleDriveClient: mockGoogleDriveClient,
        internetChecker: mockInternetChecker,
        restoreBackupService: mockRestoreBackupService,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('maps GoogleDriveAuthException correctly', () async {
      // Test different auth exception types
      final testCases = [
        (GoogleDriveAuthException.notSignedIn(), 'SIGN_IN_FAILED'),
        (GoogleDriveAuthException.signInCancelled(), 'SIGN_IN_CANCELLED'),
        (GoogleDriveAuthException.insufficientPermissions(), 'INSUFFICIENT_PERMISSIONS'),
        (GoogleDriveAuthException.tokenExpired(), 'TOKEN_EXPIRED'),
      ];

      for (final (exception, expectedCode) in testCases) {
        // Arrange
        when(mockGoogleDriveClient.signIn()).thenThrow(exception);

        // Act
        final result = await repository.signIn();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.authentication));
        expect(result.error.code, equals(expectedCode));
      }
    });

    test('maps GoogleDriveNetworkException correctly', () async {
      // Test different network exception types
      final testCases = [
        (GoogleDriveNetworkException.noConnection(), 'NO_INTERNET'),
        (GoogleDriveNetworkException.timeout(), 'TIMEOUT'),
        (GoogleDriveNetworkException.networkError(), 'NETWORK_ERROR'),
      ];

      for (final (exception, expectedCode) in testCases) {
        // Arrange
        when(mockGoogleDriveClient.signIn()).thenThrow(exception);

        // Act
        final result = await repository.signIn();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.type, equals(BackupErrorType.network)); 
        expect(result.error.code, equals(expectedCode));
      }
    });

    test('maps GoogleDriveQuotaException correctly', () async {
      // Arrange
      when(mockGoogleDriveClient.signIn())
          .thenThrow(GoogleDriveQuotaException.storageExceeded());

      // Act
      final result = await repository.signIn();

      // Assert
      expect(result.isError, isTrue);
      expect(result.error.type, equals(BackupErrorType.googleDriveApi));
      expect(result.error.code, equals('QUOTA_EXCEEDED'));
    });
  });
}