import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/constants/env.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/backup_sources/backup_file_constructor.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:storypad/initializers/device_info_initializer.dart';
import 'package:storypad/initializers/file_initializer.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/local_widgets/backup_object_viewer.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

import 'offline_backups_view.dart';

class OfflineBackupViewModel extends BaseViewModel {
  final OfflineBackupRoute params;

  OfflineBackupViewModel({
    required this.params,
  });

  Future<(String, File)> backup(DateTime lastDbUpdatedAt) async {
    final backup = await BackupFileConstructor().constructBackup(
      databases: BaseBackupSource.databases,
      lastUpdatedAt: lastDbUpdatedAt,
    );

    final fileAppLevelPath = "backups/sahakom-$kAppName-${kDeviceInfo.model}-backup-all.json";
    final file = File("${kApplicationDirectory.path}/$fileAppLevelPath");

    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(backup.toContents()));

    if (Platform.isAndroid) {
      String readableParentPath = "/Android/data/${kApplicationDirectory.path.split("/Android/data/").last}";
      String readableFilePath = "$readableParentPath/backups";
      return (readableFilePath, file);
    } else if (Platform.isIOS) {
      return (fileAppLevelPath, file);
    }

    return (file.path, file);
  }

  Future<void> export(BuildContext context) async {
    DateTime? lastDbUpdatedAt = context.read<BackupProvider>().lastDbUpdatedAt;
    if (lastDbUpdatedAt == null) return;

    final result = await MessengerService.of(context).showLoading(
      future: () => backup(lastDbUpdatedAt),
      debugSource: '$runtimeType#export',
    );

    if (!context.mounted || result == null) return;
    MessengerService.of(context).showSnackBar("Saved to ${result.$1}", action: (foreground) {
      return SnackBarAction(
        label: "Share",
        textColor: foreground,
        onPressed: () => Share.shareXFiles([XFile(result.$2.path)]),
      );
    });
  }

  Future<void> import(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      initialDirectory: kApplicationDirectory.parent.path,
      allowedExtensions: ['json'],
    );

    final file = result?.files.firstOrNull;
    final jsonString = await file?.xFile.readAsString();

    if (jsonString != null) {
      Map<String, dynamic>? contents;
      BackupObject? backup;

      try {
        contents = jsonDecode(jsonString);
        backup = BackupObject.fromContents(contents!);
      } catch (e) {
        if (context.mounted) MessengerService.of(context).showSnackBar("Empty or invalid file!", success: false);
        return;
      }

      if (!context.mounted) return;

      SpNestedNavigation.maybeOf(context)?.push(
        BackupObjectViewer(backup: backup),
      );
    }
  }
}
