import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/google_drive_client.dart';

class BackupLatestCheckerResponse {
  final bool hasError;
  final CloudFileObject? lastestBackupFile;
  final BackupObject? backupContent;

  DateTime? get lastSyncedAt => lastestBackupFile?.getFileInfo()?.createdAt;

  BackupLatestCheckerResponse({
    required this.hasError,
    required this.lastestBackupFile,
    required this.backupContent,
  });
}

class BackupLatestCheckerService {
  final StreamController<BackupSyncMessage?> controller = StreamController<BackupSyncMessage?>.broadcast();
  Stream<BackupSyncMessage?> get message => controller.stream;

  void reset() {
    controller.add(null);
  }

  Future<BackupLatestCheckerResponse> start(GoogleDriveClient client, DateTime? lastDbUpdatedAt) async {
    debugPrint('🚧 $runtimeType#start ...');

    return _start(client, lastDbUpdatedAt).onError((e, s) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Failed to check backup due to $e',
      ));
      return BackupLatestCheckerResponse(
        hasError: true,
        lastestBackupFile: null,
        backupContent: null,
      );
    });
  }

  Future<BackupLatestCheckerResponse> _start(GoogleDriveClient client, DateTime? lastDbUpdatedAt) async {
    controller.add(BackupSyncMessage(processing: true, success: null, message: null));
    final lastestBackupFile = await client.fetchLatestBackup();

    if (lastestBackupFile == null) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: true,
        message: 'Everything is up to date',
      ));

      return BackupLatestCheckerResponse(
        hasError: false,
        lastestBackupFile: lastestBackupFile,
        backupContent: null,
      );
    }

    if (lastestBackupFile.getFileInfo()?.createdAt == lastDbUpdatedAt) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: true,
        message: 'Everything is up to date',
      ));

      return BackupLatestCheckerResponse(
        lastestBackupFile: lastestBackupFile,
        backupContent: null,
        hasError: false,
      );
    }

    final result = await client.getFileContent(lastestBackupFile);
    final fileContent = result?.$1;

    if (fileContent == null) {
      controller.add(BackupSyncMessage(
        processing: false,
        success: false,
        message: 'Could not fetch file content!',
      ));

      return BackupLatestCheckerResponse(
        lastestBackupFile: lastestBackupFile,
        backupContent: null,
        hasError: true,
      );
    }

    dynamic decodedContents = jsonDecode(fileContent);
    final backupContent = BackupObject.fromContents(decodedContents);

    controller.add(BackupSyncMessage(
      processing: false,
      success: true,
      message: 'Backup found: ${lastestBackupFile.fileName}',
    ));

    return BackupLatestCheckerResponse(
      lastestBackupFile: lastestBackupFile,
      backupContent: backupContent,
      hasError: false,
    );
  }
}
