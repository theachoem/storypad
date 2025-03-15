import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/views/backups/show/show_backup_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'backups_view.dart';

class BackupsViewModel extends BaseViewModel {
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

  Future<void> load(BuildContext context) async {
    if (context.read<BackupProvider>().source.isSignedIn == null ||
        context.read<BackupProvider>().source.isSignedIn == false) {
      loading = false;
      files = null;
      notifyListeners();
      return;
    }

    loading = true;
    files = await context.read<BackupProvider>().source.fetchAllCloudFiles().then((e) => e?.files);

    if (context.mounted) deleteOldBackupsSilently(context);

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
      backupsGroupByDevice[file.getFileInfo()?.device.id ?? tr("general.na")]
          ?.sort((a, b) => a.getFileInfo()!.createdAt.compareTo(b.getFileInfo()!.createdAt));
    }

    for (final entry in backupsGroupByDevice.entries) {
      if (entry.value.length > 1) {
        // delete old backup & keep last 1
        toRemoveBackupsIds = entry.value.take(entry.value.length - 1).map((e) => e.id).toSet();
        files?.removeWhere((e) => toRemoveBackupsIds.contains(e.id));
      }
    }

    for (String id in toRemoveBackupsIds) {
      context.read<BackupProvider>().queueDeleteBackupState.delete(id);
    }
  }

  Future<void> openCloudFile(
    BuildContext context,
    CloudFileObject cloudFile,
  ) async {
    BackupObject? backup = loadedBackups[cloudFile.id] ??
        await MessengerService.of(context).showLoading(
          future: () => context.read<BackupProvider>().source.getBackup(cloudFile),
          debugSource: '$runtimeType#openCloudFile',
        );

    if (backup != null && context.mounted) {
      loadedBackups[cloudFile.id] = backup;
      ShowBackupsRoute(backup).push(context);
    }
  }

  Future<void> deleteCloudFile(BuildContext context, CloudFileObject file) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#deleteCloudFile',
      future: () async {
        await context.read<BackupProvider>().deleteCloudFile(file);
        files?.removeWhere((e) => e.id == file.id);
        notifyListeners();
      },
    );
  }

  Future<void> signOut(BuildContext context) async {
    await context
        .read<BackupProvider>()
        .signOut(context: context, showLoading: true, debugSource: '$runtimeType#signOut');
    if (context.mounted) await load(context);
  }

  Future<void> signIn(BuildContext context) async {
    await context
        .read<BackupProvider>()
        .signIn(context: context, showLoading: true, debugSource: '$runtimeType#signIn');
    if (context.mounted) await load(context);
  }
}
