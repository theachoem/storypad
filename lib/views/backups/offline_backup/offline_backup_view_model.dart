import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/constants/env.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/core/services/backup_sources/backup_file_constructor.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:storypad/initializers/device_info_initializer.dart';
import 'package:storypad/initializers/file_initializer.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/local_widgets/backup_object_viewer.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

import 'offline_backup_view.dart';

class OfflineBackupViewModel extends BaseViewModel {
  final OfflineBackupRoute params;
  final String exportFileName = "$kAppName-${kDeviceInfo.model}-backup-all.json";
  final String parentName = "backups";

  OfflineBackupViewModel({
    required this.params,
  });

  Future<void> import(BuildContext context) async {
    AnalyticsService.instance.logImportOfflineBackup();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      initialDirectory: kApplicationDirectory.parent.path,
      allowedExtensions: ['json'],
    );

    if (!context.mounted) return;

    final file = result?.files.firstOrNull;
    if (file == null) return;

    final backup = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#import',
      future: () => Isolate.run(() async {
        final jsonString = await file.xFile.readAsString();
        Map<String, dynamic>? contents;

        try {
          contents = jsonDecode(jsonString);
          return BackupObject.fromContents(contents!);
        } catch (e) {
          return null;
        }
      }),
    );

    if (!context.mounted) return;
    if (backup == null) {
      MessengerService.of(context).showSnackBar("Empty or invalid file!", success: false);
      return;
    }

    MessengerService.of(context).clearSnackBars();
    SpNestedNavigation.maybeOf(context)?.push(
      BackupObjectViewer(backup: backup),
    );
  }

  Future<void> export(BuildContext context) async {
    AnalyticsService.instance.logExportOfflineBackup();

    DateTime? lastDbUpdatedAt = context.read<BackupProvider>().lastDbUpdatedAt;
    if (lastDbUpdatedAt == null) return;

    final file = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#export',
      future: () => _constructBackupAndSaveToApplicationFolder(context, lastDbUpdatedAt),
    );

    if (file == null || !context.mounted) return;
    Share.shareXFiles([XFile(file.path)]);
  }

  Future<File> _constructBackupAndSaveToApplicationFolder(
    BuildContext context,
    DateTime lastDbUpdatedAt,
  ) async {
    BackupObject backup = await BackupFileConstructor().constructBackup(
      databases: BaseBackupSource.databases,
      lastUpdatedAt: lastDbUpdatedAt,
    );

    final file = File("${kApplicationDirectory.path}/$parentName/$exportFileName");

    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(backup.toContents()));

    return file;
  }
}
