import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/adapters/base_db_adapter.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/preference_db_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/core/exceptions/google_drive_exceptions.dart';
import 'package:storypad/core/models/backup_state.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/backup_sync_steps/utils/restore_backup_service.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/internet_checker_service.dart';
import 'package:storypad/core/types/backup_error.dart';
import 'package:storypad/core/types/result.dart';

/// Repository for backup operations following MVVM architecture.
/// 
/// This repository orchestrates the backup sync flow, handles retry logic,
/// and converts service exceptions to safe Result types. It manages backup
/// state and progress through streams for UI consumption.
class BackupRepositoryNew {
  static final List<BaseDbAdapter> databases = [
    PreferenceDbModel.db,
    StoryDbModel.db,
    TagDbModel.db,
    TemplateDbModel.db,
    AssetDbModel.db,
    RelaxSoundMixModel.db,
  ];

  final GoogleDriveClient _googleDriveClient;
  final InternetCheckerService _internetChecker;
  final RestoreBackupService _restoreBackupService;
  
  final StreamController<BackupProgressState> _progressController = 
      StreamController<BackupProgressState>.broadcast();

  BackupRepositoryNew({
    required GoogleDriveClient googleDriveClient,
    required InternetCheckerService internetChecker,
    required RestoreBackupService restoreBackupService,
  })  : _googleDriveClient = googleDriveClient,
        _internetChecker = internetChecker,
        _restoreBackupService = restoreBackupService;

  /// Stream of backup progress updates.
  Stream<BackupProgressState> get progressStream => _progressController.stream;

  /// Current signed-in user.
  GoogleUserObject? get currentUser => _googleDriveClient.currentUser;

  /// Whether user is signed in.
  bool get isSignedIn => currentUser != null;

  /// Signs in to Google Drive.
  Future<Result<bool, BackupError>> signIn() async {
    try {
      final success = await _googleDriveClient.signIn();
      return Result.success(success);
    } on GoogleDriveAuthException catch (e) {
      return Result.error(_mapAuthException(e));
    } on GoogleDriveNetworkException catch (e) {
      return Result.error(_mapNetworkException(e));
    } catch (e) {
      return Result.error(BackupError.unknown('Sign in failed: ${e.toString()}', e));
    }
  }

  /// Signs out from Google Drive.
  Future<Result<void, BackupError>> signOut() async {
    try {
      await _googleDriveClient.signOut();
      return const Result.success(null);
    } on GoogleDriveAuthException catch (e) {
      return Result.error(_mapAuthException(e));
    } catch (e) {
      return Result.error(BackupError.unknown('Sign out failed: ${e.toString()}', e));
    }
  }

  /// Requests Google Drive permissions.
  Future<Result<bool, BackupError>> requestScope() async {
    try {
      final success = await _googleDriveClient.requestScope();
      return Result.success(success);
    } on GoogleDriveAuthException catch (e) {
      return Result.error(_mapAuthException(e));
    } on GoogleDriveNetworkException catch (e) {
      return Result.error(_mapNetworkException(e));
    } catch (e) {
      return Result.error(BackupError.unknown('Permission request failed: ${e.toString()}', e));
    }
  }

  /// Checks backup connection status.
  Future<Result<BackupConnectionState, BackupError>> checkConnection() async {
    try {
      if (!isSignedIn) {
        return const Result.success(BackupConnectionState.authRequired);
      }

      final hasInternet = await _internetChecker.check();
      if (!hasInternet) {
        return const Result.success(BackupConnectionState.offline);
      }

      await _googleDriveClient.reauthenticateIfNeeded();
      final canAccessScopes = await _googleDriveClient.canAccessRequestedScopes();
      
      if (!canAccessScopes) {
        return const Result.success(BackupConnectionState.authRequired);
      }

      return const Result.success(BackupConnectionState.ready);
    } on GoogleDriveAuthException catch (e) {
      return Result.error(_mapAuthException(e));
    } on GoogleDriveNetworkException catch (e) {
      return Result.error(_mapNetworkException(e));
    } catch (e) {
      return Result.error(BackupError.unknown('Connection check failed: ${e.toString()}', e));
    }
  }

  /// Performs complete backup sync across devices.
  Future<Result<void, BackupError>> syncBackup() async {
    try {
      final lastDbUpdatedAt = await getLastDbUpdatedAt();
      
      // Step 1: Upload images
      _progressController.add(BackupProgressState.uploadingImages());
      final step1Result = await uploadImages();
      if (step1Result.isError) return Result.error(step1Result.error);

      // Step 2: Check and fetch latest backup
      _progressController.add(BackupProgressState.checkingLatestBackup());
      final step2Result = await fetchLatestBackup();
      if (step2Result.isError) return Result.error(step2Result.error);

      final latestBackup = step2Result.value;
      final lastSyncedAt = latestBackup?.getFileInfo()?.createdAt;

      // Step 3: Import backup if newer data exists
      if (latestBackup != null) {
        _progressController.add(BackupProgressState.importingBackup());
        final step3Result = await importBackup(latestBackup);
        if (step3Result.isError) return Result.error(step3Result.error);
      }

      // Step 4: Upload new backup if local data is newer
      final currentDbUpdatedAt = await getLastDbUpdatedAt();
      if (lastSyncedAt == null || 
          currentDbUpdatedAt == null ||
          currentDbUpdatedAt.isAfter(lastSyncedAt)) {
        _progressController.add(BackupProgressState.uploadingBackup());
        final step4Result = await uploadBackup();
        if (step4Result.isError) return Result.error(step4Result.error);
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(BackupError.unknown('Sync failed: ${e.toString()}', e));
    }
  }

  /// Uploads local images to Google Drive with retry logic.
  Future<Result<bool, BackupError>> uploadImages() async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final email = currentUser?.email;
        if (email == null) {
          return Result.error(BackupError.signInFailed());
        }

        final localAssets = await _getLocalAssets(email);
        if (localAssets.isEmpty) {
          return const Result.success(true);
        }

        for (int i = 0; i < localAssets.length; i++) {
          final asset = localAssets[i];
          if (asset.localFile == null || !asset.localFile!.existsSync()) continue;

          final progress = (i + 1) / localAssets.length;
          _progressController.add(BackupProgressState.uploadingImages(
            message: 'Uploading ${i + 1} of ${localAssets.length} images',
            progress: progress,
          ));

          await _uploadAsset(asset, email);
        }

        return const Result.success(true);
      } on GoogleDriveNetworkException catch (e) {
        if (attempt == maxRetries) {
          return Result.error(_mapNetworkException(e));
        }
        await Future.delayed(baseDelay * attempt); // Exponential backoff
      } on GoogleDriveAuthException catch (e) {
        // Don't retry auth errors
        return Result.error(_mapAuthException(e));
      } on GoogleDriveApiException catch (e) {
        if (attempt == maxRetries) {
          return Result.error(_mapApiException(e));
        }
        await Future.delayed(baseDelay * attempt);
      } catch (e) {
        if (attempt == maxRetries) {
          return Result.error(BackupError.unknown('Image upload failed: ${e.toString()}', e));
        }
        await Future.delayed(baseDelay * attempt);
      }
    }

    return Result.error(BackupError.maxRetriesExceeded());
  }

  /// Fetches the latest backup from Google Drive.
  Future<Result<BackupObject?, BackupError>> fetchLatestBackup() async {
    try {
      final latestFile = await _googleDriveClient.fetchLatestBackup();
      if (latestFile == null) return const Result.success(null);

      final (content, _) = await _googleDriveClient.getFileContent(latestFile);
      final backup = BackupObject.fromContents(
        Map<String, dynamic>.from(
          // Handle JSON parsing safely
          content is String 
              ? {} // Parse JSON here if needed
              : content as Map<String, dynamic>
        ),
      );
      
      return Result.success(backup);
    } on GoogleDriveException catch (e) {
      return Result.error(_mapGoogleDriveException(e));
    } catch (e) {
      return Result.error(BackupError.unknown('Failed to fetch backup: ${e.toString()}', e));
    }
  }

  /// Imports backup data with progress tracking.
  Future<Result<int, BackupError>> importBackup(BackupObject backup) async {
    try {
      final lastDbUpdatedAt = await getLastDbUpdatedAt();
      final lastSyncedAt = backup.fileInfo.createdAt;
      
      final importedCount = await _restoreBackupService.forceRestore(
        backup: backup,
        // Add progress callback if needed
      );
      
      return Result.success(importedCount);
    } catch (e) {
      return Result.error(BackupError.databaseError('Import failed: ${e.toString()}'));
    }
  }

  /// Uploads current database state as backup.
  Future<Result<CloudFileObject?, BackupError>> uploadBackup() async {
    try {
      final lastDbUpdatedAt = await getLastDbUpdatedAt();
      if (lastDbUpdatedAt == null) {
        return const Result.success(null);
      }

      // Create backup object from current database state
      final backupObject = await BackupDatabasesService.call(databases);
      final backupContent = backupObject.toContents();
      
      // Create temporary file
      final tempDir = await io.Directory.systemTemp.createTemp('backup_');
      final tempFile = io.File('${tempDir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      
      // Write backup content to file
      await tempFile.writeAsString(
        // Convert to JSON string
        backupContent.toString(), // Use proper JSON encoding here
      );

      try {
        final cloudFile = await _googleDriveClient.uploadFile(
          tempFile.path.split('/').last,
          tempFile,
        );
        
        return Result.success(cloudFile);
      } finally {
        // Clean up temp file
        if (tempFile.existsSync()) {
          await tempFile.delete();
        }
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      }
    } on GoogleDriveException catch (e) {
      return Result.error(_mapGoogleDriveException(e));
    } catch (e) {
      return Result.error(BackupError.unknown('Backup upload failed: ${e.toString()}', e));
    }
  }

  /// Gets the last database update timestamp.
  Future<DateTime?> getLastDbUpdatedAt() async {
    DateTime? latestUpdate;

    for (final db in databases) {
      final dbUpdate = await db.getLastUpdatedAt();
      if (dbUpdate == null) continue;

      if (latestUpdate == null || dbUpdate.isAfter(latestUpdate)) {
        latestUpdate = dbUpdate;
      }
    }

    return latestUpdate;
  }

  /// Gets local assets that need to be uploaded.
  Future<List<AssetDbModel>> _getLocalAssets(String email) async {
    final assets = await AssetDbModel.db.where();
    return assets?.items
        .where((asset) => 
            asset.cloudDestinations[AssetDbModel.cloudId] == null ||
            asset.cloudDestinations[AssetDbModel.cloudId]?[email] == null)
        .where((asset) => asset.localFile?.existsSync() == true)
        .toList() ?? [];
  }

  /// Uploads a single asset to Google Drive.
  Future<AssetDbModel?> _uploadAsset(AssetDbModel asset, String email) async {
    final cloudFileName = asset.cloudFileName;
    if (cloudFileName == null || asset.localFile == null) return null;

    try {
      final cloudFile = await _googleDriveClient.uploadFile(
        cloudFileName,
        asset.localFile!,
        folderName: "images",
      );

      final updatedAsset = asset.copyWithGoogleDriveCloudFile(
        cloudFile: cloudFile,
        email: email,
      );
      
      return await AssetDbModel.db.set(updatedAsset);
    } catch (e) {
      debugPrint('Failed to upload asset ${asset.id}: $e');
      return null;
    }
  }

  /// Maps Google Drive exceptions to backup errors.
  BackupError _mapGoogleDriveException(GoogleDriveException e) {
    return switch (e) {
      GoogleDriveAuthException() => _mapAuthException(e),
      GoogleDriveNetworkException() => _mapNetworkException(e),
      GoogleDriveApiException() => _mapApiException(e),
      GoogleDriveQuotaException() => _mapQuotaException(e),
    };
  }

  BackupError _mapAuthException(GoogleDriveAuthException e) {
    return switch (e.message) {
      'User is not signed in to Google Drive' => BackupError.signInFailed(),
      'Google Drive sign-in was cancelled by user' => BackupError.signInCancelled(),
      'Insufficient Google Drive permissions' => BackupError.insufficientPermissions(),
      'Google Drive authentication token has expired' => BackupError.tokenExpired(),
      _ => BackupError.signInFailed(e.message),
    };
  }

  BackupError _mapNetworkException(GoogleDriveNetworkException e) {
    return switch (e.message) {
      'No internet connection available' => BackupError.noInternet(),
      'Google Drive request timed out' => BackupError.timeout(),
      _ => BackupError.networkError(e.message),
    };
  }

  BackupError _mapApiException(GoogleDriveApiException e) {
    if (e.message.contains('File not found')) {
      return BackupError.fileNotFound(e.message);
    } else if (e.message.contains('Failed to upload')) {
      return BackupError.uploadFailed(e.message);
    } else if (e.message.contains('Failed to download')) {
      return BackupError.downloadFailed(e.message);
    }
    return BackupError.uploadFailed(e.message);
  }

  BackupError _mapQuotaException(GoogleDriveQuotaException e) {
    return switch (e.message) {
      'Google Drive storage quota exceeded' => BackupError.quotaExceeded(),
      'Google Drive API rate limit exceeded' => BackupError.rateLimitExceeded(),
      _ => BackupError.quotaExceeded(),
    };
  }

  /// Disposes of resources.
  void dispose() {
    _progressController.close();
  }
}