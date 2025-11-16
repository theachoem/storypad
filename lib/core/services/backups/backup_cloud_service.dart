import 'dart:io' as io;
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

/// Abstract base class for cloud backup services
/// Implementations: GoogleDriveClient, OneDriveClient, etc.
abstract class BackupCloudService {
  /// The service type metadata for this implementation
  BackupServiceType get serviceType;

  /// User currently authenticated with this cloud service
  GoogleUserObject? get currentUser;
  bool get isSignedIn => currentUser != null;

  /// Initialize the cloud service (load stored credentials)
  Future<void> initialize();

  /// Request necessary scopes/permissions from the cloud service
  Future<bool> requestScope();

  /// Reauthenticate if token has expired
  Future<bool> reauthenticateIfNeeded();

  /// Verify access to requested scopes
  Future<bool> canAccessRequestedScopes();

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

  /// Upload a new yearly backup file
  Future<CloudFileObject?> uploadYearlyBackup({
    required String fileName,
    required io.File file,
  });

  /// Update an existing yearly backup file (atomic)
  /// Uses file ID to prevent race conditions
  Future<CloudFileObject?> updateYearlyBackup({
    required String fileId,
    required String fileName,
    required io.File file,
  });

  /// Find a file by ID in cloud storage
  Future<CloudFileObject?> findFileById(String fileId);

  /// Delete a file from cloud storage
  Future<bool> deleteFile(String cloudFileId);

  /// Upload a file (asset) to cloud storage
  /// Returns: CloudFileObject metadata if successful
  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  });
}
