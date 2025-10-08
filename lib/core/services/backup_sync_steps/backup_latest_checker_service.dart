import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backup_sync_steps/backup_sync_message.dart';
import 'package:storypad/core/services/google_drive_client.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

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

    try {
      return await _start(client, lastDbUpdatedAt);
    } on exp.AuthException catch (e) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: e.userFriendlyMessage,
        ),
      );
      rethrow; // Let repository handle auth exceptions
    } on exp.BackupException catch (e) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: e.userFriendlyMessage,
        ),
      );
      return BackupLatestCheckerResponse(
        hasError: true,
        lastestBackupFile: null,
        backupContent: null,
      );
    } catch (e, stackTrace) {
      debugPrint('$runtimeType#start unexpected error: $e $stackTrace');
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: 'Failed to check backup due to unexpected error.',
        ),
      );
      return BackupLatestCheckerResponse(
        hasError: true,
        lastestBackupFile: null,
        backupContent: null,
      );
    }
  }

  Future<BackupLatestCheckerResponse> _start(GoogleDriveClient client, DateTime? lastDbUpdatedAt) async {
    controller.add(BackupSyncMessage(processing: true, success: null, message: null));

    final lastestBackupFile = await RetryExecutor.execute(
      () => client.fetchLatestBackup(),
      policy: RetryPolicy.network,
      operationName: 'fetch_latest_backup',
    );

    if (lastestBackupFile == null) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'Everything is up to date',
        ),
      );

      return BackupLatestCheckerResponse(
        hasError: false,
        lastestBackupFile: lastestBackupFile,
        backupContent: null,
      );
    }

    if (lastestBackupFile.getFileInfo()?.createdAt == lastDbUpdatedAt) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: true,
          message: 'Everything is up to date',
        ),
      );

      return BackupLatestCheckerResponse(
        lastestBackupFile: lastestBackupFile,
        backupContent: null,
        hasError: false,
      );
    }

    final result = await RetryExecutor.execute(
      () => client.getFileContent(lastestBackupFile),
      policy: RetryPolicy.network,
      operationName: 'download_backup_content',
    );
    final fileContent = result?.$1;

    if (fileContent == null) {
      controller.add(
        BackupSyncMessage(
          processing: false,
          success: false,
          message: 'Could not fetch file content!',
        ),
      );

      return BackupLatestCheckerResponse(
        lastestBackupFile: lastestBackupFile,
        backupContent: null,
        hasError: true,
      );
    }

    BackupObject? backupContent;
    try {
      dynamic decodedContents = jsonDecode(fileContent);
      backupContent = BackupObject.fromContents(decodedContents);
    } catch (e) {
      debugPrint('$runtimeType#_start cannot parse backup content: $e');
      throw exp.ServiceException(
        'Failed to parse backup content: $e',
        exp.ServiceExceptionType.dataCorrupted,
        context: lastestBackupFile.id,
      );
    }

    controller.add(
      BackupSyncMessage(
        processing: false,
        success: true,
        message: 'Backup found: ${lastestBackupFile.fileName}',
      ),
    );

    return BackupLatestCheckerResponse(
      lastestBackupFile: lastestBackupFile,
      backupContent: backupContent,
      hasError: false,
    );
  }
}
