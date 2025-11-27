import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' show BackupException;
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backup_services/backups/show/show_backup_view.dart';
import 'show_backup_service_view.dart';

class ShowBackupServiceViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowBackupServiceRoute params;

  BackupServiceType get serviceType => params.service.serviceType;
  late final BackupProvider backupProvider;

  Map<int, CloudFileObject>? yearlyBackups;
  Map<String, BackupObject> loadedBackups = {};

  ShowBackupServiceViewModel({
    required this.params,
    required BuildContext context,
  }) {
    backupProvider = context.read<BackupProvider>();
    load();
  }

  String? errorMessage;

  /// Example output:
  /// [
  ///   MapEntry(2022, CloudFileObject(id: '123', year: 2022, lastUpdatedAt: DateTime(2022, 1, 1))),
  ///   MapEntry(2021, CloudFileObject(id: '456', year: 2021, lastUpdatedAt: DateTime(2021, 1, 1))),
  /// ]
  List<MapEntry<int, CloudFileObject>> getSortedYearlyBackups() {
    if (yearlyBackups == null) return [];
    final entries = yearlyBackups!.entries.toList();
    entries.sort((a, b) => b.key.compareTo(a.key)); // Descending order (newest first)
    return entries;
  }

  String? getLastSyncAt(BuildContext context) {
    if (yearlyBackups == null || yearlyBackups!.isEmpty) return null;
    final latest = yearlyBackups!.values
        .map((e) => e.lastUpdatedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev);
    return latest != null ? DateFormatHelper.yMEd_jmNullable(latest, context.locale) ?? '...' : null;
  }

  Future<void> load() async {
    final service = backupProvider.repository.getService(serviceType);
    errorMessage = null;

    try {
      yearlyBackups = await service.fetchYearlyBackups();
    } on BackupException catch (e) {
      yearlyBackups = {};
      errorMessage = e.message;
    }

    notifyListeners();
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
            final result = await context.read<BackupProvider>().repository.googleDriveService.getFileContent(cloudFile);

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
        bool? success = await context.read<BackupProvider>().repository.googleDriveService.deleteFile(file.id);
        if (success == true) yearlyBackups?.remove(file.year);
        notifyListeners();
      },
    );
  }

  void signOut(BuildContext context) async {
    await context.read<BackupProvider>().signOut(context, serviceType);
    if (context.mounted) Navigator.maybePop(context);
  }
}
