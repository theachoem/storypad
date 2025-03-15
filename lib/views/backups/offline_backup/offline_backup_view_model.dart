import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/services/backup_sources/backup_databases_to_backup_object_service.dart';
import 'package:storypad/views/backups/show/show_backup_view.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:storypad/providers/backup_provider.dart';

import 'offline_backup_view.dart';

class OfflineBackupsViewModel extends BaseViewModel {
  final OfflineBackupsRoute params;
  final String parentName = "backups";

  OfflineBackupsViewModel({
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
      MessengerService.of(context).showSnackBar(tr("snack_bar.empty_or_invalid_file"), success: false);
      return;
    }

    MessengerService.of(context).clearSnackBars();
    ShowBackupsRoute(backup).push(context);
  }

  Future<void> export(BuildContext context) async {
    AnalyticsService.instance.logExportOfflineBackup();

    DateTime? lastDbUpdatedAt = context.read<BackupProvider>().lastDbUpdatedAt;
    if (lastDbUpdatedAt == null) return;

    final String exportFileName = "$kAppName-${kDeviceInfo.model}-backup-${DateTime.now().toIso8601String()}.json";

    final backup = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#export',
      future: () => BackupDatabasesToBackupObjectService.call(
        databases: BaseBackupSource.databases,
        lastUpdatedAt: lastDbUpdatedAt,
      ),
    );

    if (backup == null || !context.mounted) return;
    if (Platform.isIOS) {
      final file = File("${kSupportDirectory.path}/$parentName/$exportFileName");

      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(backup.toContents()));

      await FilePicker.platform.saveFile(
        fileName: exportFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: file.readAsBytesSync(),
      );

      await Share.shareXFiles([XFile(file.path)]);
      await file.delete();
    } else if (Platform.isAndroid) {
      await FilePicker.platform.saveFile(
        fileName: exportFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonEncode(backup.toContents())),
      );
    } else {
      throw UnimplementedError();
    }
  }
}
