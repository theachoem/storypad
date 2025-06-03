import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/backup/backup_syncer_service.dart';
import 'package:storypad/core/services/backup/google_drive_client_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/show/show_backup_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/messenger_service.dart';
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

  Future<void> load(BuildContext context) async {
    if (context.read<BackupProvider>().currentUser == null) {
      loading = false;
      files = null;
      notifyListeners();
      return;
    }

    loading = true;
    files = await GoogleDriveClientService().fetchAllCloudFiles().then((e) => e?.files);

    loading = false;
    notifyListeners();
  }

  Future<void> openCloudFile(
    BuildContext context,
    CloudFileObject cloudFile,
  ) async {
    BackupObject? backup = loadedBackups[cloudFile.id] ??
        await MessengerService.of(context).showLoading(
          future: () => BackupSyncerService(GoogleDriveClientService()).getBackupFromCloudFile(cloudFile),
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
        bool deleted = await GoogleDriveClientService().deleteCloudFile(file);
        if (deleted) files?.removeWhere((e) => e.id == file.id);
        notifyListeners();
      },
    );
  }

  Future<void> signOut(BuildContext context) async {
    await context.read<BackupProvider>().signOut();
    if (context.mounted) await load(context);
  }

  Future<void> signIn(BuildContext context) async {
    await context.read<BackupProvider>().signIn();
    if (context.mounted) await load(context);
  }
}
