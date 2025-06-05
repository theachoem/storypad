import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/google_drive_client.dart';

class BackupLatestCheckerService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  BackupObject? _cacheBackup;
  BackupObject? get cacheBackup => _cacheBackup;

  void reset() {
    _cacheBackup = null;
    controller.add(null);
  }

  void clearCacheBackup() {
    _cacheBackup = null;
  }

  Future<bool> start(GoogleDriveClient client, DateTime? lastDbUpdatedAt) async {
    try {
      debugPrint('🚧 $runtimeType#start ...');
      return _start(client, lastDbUpdatedAt);
    } catch (e) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Failed to check backup due to $e',
      ));
      return false;
    }
  }

  Future<bool> _start(GoogleDriveClient client, DateTime? lastDbUpdatedAt) async {
    controller.add(BackupSyncMessage(processing: true, success: null, message: null));
    final latestBackup = await client.fetchLatestBackup();

    if (latestBackup == null) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: true,
        message: 'Everything is up to date',
      ));
      return true;
    }

    if (latestBackup.getFileInfo()?.createdAt == lastDbUpdatedAt) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: true,
        message: 'Everything',
      ));
    }

    controller.add(BackupSyncMessage(processing: true, success: null, message: null));
    final fileContent = await client.getFileContent(latestBackup);
    if (fileContent == null) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Could not fetch file content!',
      ));
      return false;
    }

    dynamic decodedContents = jsonDecode(fileContent);
    _cacheBackup = BackupObject.fromContents(decodedContents);

    controller.add(BackupSyncMessage(
      processing: false,
      success: true,
      message: 'Backup found: ${latestBackup.fileName}',
    ));

    return true;
  }
}
