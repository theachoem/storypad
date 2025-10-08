import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/views/backups/show/show_backup_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'backups_view.dart';

class BackupsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final BackupsRoute params;

  BackupsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    load(context);
  }

  bool loading = true;

  Map<String, BackupObject> loadedBackups = {};
  List<CloudFileObject>? files;

  bool get hasData => files?.isNotEmpty == true;
  String? errorMessage;

  Future<void> load(BuildContext context) async {
    errorMessage = null;

    if (context.read<BackupProvider>().isSignedIn == false) {
      loading = false;
      files = null;
      notifyListeners();
      return;
    }

    loading = true;

    try {
      files = await context
          .read<BackupProvider>()
          .repository
          .googleDriveClient
          .fetchAllBackups(null)
          .then((e) => e?.files);
      if (context.mounted) deleteOldBackupsSilently(context);
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('$runtimeType#load failed $e');
    }

    loading = false;
    notifyListeners();
  }

  void deleteOldBackupsSilently(BuildContext context) {
    Set<String> toRemoveBackupsIds = {};

    Map<String, List<CloudFileObject>> backupsGroupByDevice = SplayTreeMap();
    for (CloudFileObject file in files ?? []) {
      if (file.getFileInfo() == null) return;

      backupsGroupByDevice[file.getFileInfo()?.device.id ?? tr("general.na")] ??= [];
      backupsGroupByDevice[file.getFileInfo()?.device.id ?? tr("general.na")]?.add(file);
      backupsGroupByDevice[file.getFileInfo()?.device.id ?? tr("general.na")]?.sort(
        (a, b) => a.getFileInfo()!.createdAt.compareTo(b.getFileInfo()!.createdAt),
      );
    }

    for (final entry in backupsGroupByDevice.entries) {
      if (entry.value.length > 1) {
        // delete old backup & keep last 1
        toRemoveBackupsIds = entry.value.take(entry.value.length - 1).map((e) => e.id).toSet();
        files?.removeWhere((e) => toRemoveBackupsIds.contains(e.id));
      }
    }

    for (String id in toRemoveBackupsIds) {
      context.read<BackupProvider>().repository.googleDriveClient.deleteFile(id);
    }
  }

  Future<void> openCloudFile(
    BuildContext context,
    CloudFileObject cloudFile,
  ) async {
    BackupObject? backup =
        loadedBackups[cloudFile.id] ??
        await MessengerService.of(context).showLoading(
          debugSource: '$runtimeType#openCloudFile',
          future: () async {
            final result = await context.read<BackupProvider>().repository.googleDriveClient.getFileContent(cloudFile);

            final fileContent = result?.$1;

            if (fileContent == null) return null;
            dynamic decodedContents = jsonDecode(fileContent);

            final backupContent = BackupObject.fromContents(decodedContents);
            backupContent.originalFileSize = result?.$2;

            return backupContent;
          },
        );

    if (backup != null && context.mounted) {
      loadedBackups[cloudFile.id] = backup;
      ShowBackupsRoute(backup).push(context);
    }
  }

  Future<void> deleteCloudFile(BuildContext context, CloudFileObject file) async {
    AnalyticsService.instance.logDeleteCloudBackup(file: file);

    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#deleteCloudFile',
      future: () async {
        bool? success = await context.read<BackupProvider>().repository.googleDriveClient.deleteFile(file.id);
        if (success == true) files?.removeWhere((e) => e.id == file.id);
        notifyListeners();
      },
    );
  }

  Future<void> signOut(BuildContext context) async {
    await context.read<BackupProvider>().signOut(context);
    if (context.mounted) await load(context);
  }

  Future<void> signIn(BuildContext context) async {
    await context.read<BackupProvider>().signIn(context);
    if (context.mounted) await load(context);
  }
}
