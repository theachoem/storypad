import 'dart:io' as io;
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

/// Abstract base class for cloud backup services
/// Implementations: GoogleDriveClient, OneDriveClient, etc.
abstract class BackupCloudService {
  /// The service type metadata for this implementation
  BackupServiceType get serviceType;

  /// User currently authenticated with this cloud service
  CloudServiceUser? get currentUser;
  bool get isSignedIn => currentUser != null;
  bool get autoBackupEnabled => currentUser?.autoBackupEnabled ?? true;

  bool get hasCompression => serviceType == BackupServiceType.google_drive;

  /// Initialize the cloud service (load stored credentials)
  Future<void> initialize();

  /// Request necessary scopes/permissions from the cloud service
  Future<bool> requestScope();

  /// Reauthenticate if token has expired
  Future<bool> reauthenticateIfNeeded();

  /// Verify access to requested scopes
  Future<bool> canAccessRequestedScopes();

  void setAutoBackupEnabled(bool enabled);

  /// Sign in to the cloud service
  Future<bool> signIn();

  /// Sign out from the cloud service
  Future<void> signOut();

  /// Fetch all yearly backups from cloud storage
  /// Returns: Map of year -> CloudFileObject metadata
  Future<Map<int, CloudFileObject>> fetchYearlyBackups();

  /// Get file content and size
  /// Returns: Tuple of (content, size)
  Future<(String, int)?> getFileContent(CloudFileObject file);

  /// Upload a new yearly backup file to the backups/ folder
  Future<CloudFileObject?> uploadYearlyBackup({
    required String fileName,
    required io.File file,
  }) async {
    return uploadFile(
      fileName,
      file,
      folderName: 'backups',
    );
  }

  /// Update an existing yearly backup file (atomic)
  /// Uses file ID to prevent race conditions
  Future<CloudFileObject?> updateYearlyBackup({
    required String fileId,
    required String fileName,
    required io.File file,
  }) {
    return updateFile(
      fileId: fileId,
      fileName: fileName,
      file: file,
    );
  }

  /// Find a file by ID in cloud storage
  Future<CloudFileObject?> findFileById(String fileId);

  /// Find a file by ID, including files that have been moved to trash
  Future<CloudFileObject?> findFileByIdIncludingTrashed(String fileId);

  /// Delete a file from cloud storage
  Future<bool> deleteFile(String cloudFileId);

  /// Move a file to trash (recoverable) instead of permanently deleting it
  Future<bool> trashFile(String cloudFileId);

  /// Restore a previously trashed file back to its original location
  Future<bool> restoreFileFromTrash(String cloudFileId);

  /// Upload a file (asset) to cloud storage
  /// Returns: CloudFileObject metadata if successful
  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  });

  // Update an existing file in cloud storage
  Future<CloudFileObject?> updateFile({
    required String fileId,
    required String fileName,
    required io.File file,
  });

  /// Fetch cloud storage quota for the signed-in user.
  /// Returns null if not signed in or unsupported by this service.
  Future<CloudStorageQuotaObject?> fetchStorageQuota();

  /// List all files inside a named folder in cloud storage.
  /// Used by the optimize screen to detect orphaned / stale-duplicate asset files.
  /// Returns an empty list if not signed in or the folder does not exist.
  Future<List<CloudFileObject>> listFilesInFolder(String folderName);
}
