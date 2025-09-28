import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/models/backup_state.dart';
import 'package:storypad/core/models/backup_ui_state.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/types/backup_error.dart';

/// Integration tests demonstrating the new backup architecture.
/// 
/// These tests validate that the MVVM pattern works correctly and that
/// the UI state flows properly through the system.
void main() {
  group('Backup Architecture Integration', () {
    test('BackupUIState transitions work correctly', () {
      // Test state transitions from initial to ready
      final initial = BackupUIState.initial();
      expect(initial.connectionState, equals(BackupConnectionState.checking));
      expect(initial.syncState, equals(BackupSyncState.idle));
      expect(initial.isSignedIn, isFalse);
      expect(initial.canSync, isFalse);

      // Test ready state
      final user = GoogleUserObject(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        accessToken: 'token',
        refreshedAt: DateTime.now(),
      );

      final ready = BackupUIState.readyToSync(currentUser: user);
      expect(ready.connectionState, equals(BackupConnectionState.ready));
      expect(ready.syncState, equals(BackupSyncState.idle));
      expect(ready.isSignedIn, isTrue);
      expect(ready.canSync, isTrue);
      expect(ready.currentUser, equals(user));

      // Test syncing state
      final progress = BackupProgressState.uploadingImages(
        message: 'Uploading 1 of 5 images',
        progress: 0.2,
      );

      final syncing = BackupUIState.syncing(
        currentUser: user,
        progressState: progress,
      );
      expect(syncing.connectionState, equals(BackupConnectionState.ready));
      expect(syncing.syncState, equals(BackupSyncState.syncing));
      expect(syncing.isSyncing, isTrue);
      expect(syncing.progressState, equals(progress));

      // Test success state
      final now = DateTime.now();
      final success = BackupUIState.syncSuccess(
        currentUser: user,
        lastSyncedAt: now,
        lastDbUpdatedAt: now,
      );
      expect(success.syncState, equals(BackupSyncState.success));
      expect(success.lastSyncSuccessful, isTrue);
      expect(success.isSynced, isTrue);

      // Test error state
      final error = BackupError.networkError('Connection failed');
      final errorState = BackupUIState.syncError(
        error: error,
        currentUser: user,
      );
      expect(errorState.syncState, equals(BackupSyncState.error));
      expect(errorState.hasError, isTrue);
      expect(errorState.error, equals(error));
    });

    test('BackupProgressState calculates overall progress correctly', () {
      // Test step 1 with 50% progress
      final step1 = BackupProgressState.uploadingImages(progress: 0.5);
      expect(step1.currentStep, equals(1));
      expect(step1.totalSteps, equals(4));
      expect(step1.overallProgress, closeTo(0.125, 0.001)); // (0 + 0.5) / 4

      // Test step 2 (no individual progress)
      final step2 = BackupProgressState.checkingLatestBackup();
      expect(step2.currentStep, equals(2));
      expect(step2.overallProgress, closeTo(0.25, 0.001)); // (1 + 0) / 4

      // Test step 3 with 75% progress
      final step3 = BackupProgressState.importingBackup(progress: 0.75);
      expect(step3.currentStep, equals(3));
      expect(step3.overallProgress, closeTo(0.6875, 0.001)); // (2 + 0.75) / 4

      // Test step 4 (final step)
      final step4 = BackupProgressState.uploadingBackup();
      expect(step4.currentStep, equals(4));
      expect(step4.overallProgress, closeTo(0.75, 0.001)); // (3 + 0) / 4
    });

    test('BackupError provides user-friendly messages', () {
      // Test authentication errors
      expect(
        BackupError.signInCancelled().userFriendlyMessage,
        contains('sign in to Google Drive'),
      );

      expect(
        BackupError.insufficientPermissions().userFriendlyMessage,
        contains('grant Google Drive permissions'),
      );

      // Test network errors
      expect(
        BackupError.noInternet().userFriendlyMessage,
        contains('No internet connection'),
      );

      expect(
        BackupError.timeout().userFriendlyMessage,
        contains('timed out'),
      );

      // Test API errors
      expect(
        BackupError.quotaExceeded().userFriendlyMessage,
        contains('storage is full'),
      );

      expect(
        BackupError.rateLimitExceeded().userFriendlyMessage,
        contains('Too many requests'),
      );

      // Test storage errors
      expect(
        BackupError.backupCorrupted().userFriendlyMessage,
        contains('corrupted'),
      );

      // Test file system errors
      expect(
        BackupError.insufficientStorage().userFriendlyMessage,
        contains('storage space'),
      );
    });

    test('UI state provides correct status messages', () {
      final user = GoogleUserObject(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        accessToken: 'token',
        refreshedAt: DateTime.now(),
      );

      // Test different state messages
      expect(
        BackupUIState.checkingConnection().statusMessage,
        equals('Checking connection...'),
      );

      expect(
        BackupUIState.offline().statusMessage,
        equals('No internet connection'),
      );

      expect(
        BackupUIState.authRequired().statusMessage,
        equals('Sign in required'),
      );

      expect(
        BackupUIState.readyToSync(currentUser: user).statusMessage,
        equals('Ready to sync'),
      );

      final now = DateTime.now();
      expect(
        BackupUIState.syncSuccess(
          currentUser: user,
          lastSyncedAt: now,
          lastDbUpdatedAt: now,
        ).statusMessage,
        equals('All data synced'),
      );

      final error = BackupError.networkError('Connection failed');
      expect(
        BackupUIState.syncError(error: error).statusMessage,
        contains('Network error'),
      );

      final progress = BackupProgressState.uploadingImages(
        message: 'Uploading images...',
      );
      expect(
        BackupUIState.syncing(
          currentUser: user,
          progressState: progress,
        ).statusMessage,
        equals('Uploading images...'),
      );
    });

    test('copyWith preserves and updates state correctly', () {
      final user = GoogleUserObject(
        id: 'test-id',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: null,
        accessToken: 'token',
        refreshedAt: DateTime.now(),
      );

      final original = BackupUIState.readyToSync(currentUser: user);
      
      // Test updating connection state
      final updated = original.copyWith(
        connectionState: BackupConnectionState.offline,
      );
      expect(updated.connectionState, equals(BackupConnectionState.offline));
      expect(updated.currentUser, equals(user)); // Should preserve other fields

      // Test clearing error
      final withError = original.copyWith(
        error: BackupError.networkError('Test error'),
      );
      expect(withError.hasError, isTrue);

      final errorCleared = withError.copyWith(clearError: true);
      expect(errorCleared.hasError, isFalse);
      expect(errorCleared.error, isNull);

      // Test clearing progress
      final progress = BackupProgressState.uploadingImages();
      final withProgress = original.copyWith(progressState: progress);
      expect(withProgress.progressState, equals(progress));

      final progressCleared = withProgress.copyWith(clearProgress: true);
      expect(progressCleared.progressState, isNull);
    });
  });
}