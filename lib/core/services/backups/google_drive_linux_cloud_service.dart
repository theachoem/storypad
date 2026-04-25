import 'dart:io' as io;

import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

/// Stub implementation of GoogleDrive backup service for Linux/FOSS builds.
/// All operations are disabled. A real local-filesystem or alternative
/// implementation can replace this later.
class GoogleDriveLinuxCloudService extends BackupCloudService {
  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

  @override
  CloudServiceUser? get currentUser => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> signIn() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> requestScope() async => false;

  @override
  Future<bool> reauthenticateIfNeeded() async => false;

  @override
  Future<bool> canAccessRequestedScopes() async => false;

  @override
  void setAutoBackupEnabled(bool enabled) {}

  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async => {};

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async => null;

  @override
  Future<bool> deleteFile(String cloudFileId) async => false;

  @override
  Future<CloudFileObject?> findFileById(String fileId) async => null;

  @override
  Future<CloudFileObject?> uploadFile(
    String fileName,
    io.File file, {
    String? folderName,
  }) async => null;

  @override
  Future<CloudFileObject?> updateFile({
    required String fileId,
    required String fileName,
    required io.File file,
  }) async => null;
}
