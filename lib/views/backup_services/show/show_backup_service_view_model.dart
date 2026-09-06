import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/objects/nextcloud_user_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/backups/icloud_cloud_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backup_services/backups/show/show_backup_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_connect_nextcloud_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_icloud_settings_sheet.dart';
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

  BackupException? error;

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
    error = null;

    try {
      yearlyBackups = await service.fetchYearlyBackups();
    } on BackupException catch (e) {
      yearlyBackups = {};
      error = e;
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
            final result = await context
                .read<BackupProvider>()
                .repository
                .getService(serviceType)
                .getFileContent(cloudFile);

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
        bool? success = await context.read<BackupProvider>().repository.getService(serviceType).deleteFile(file.id);
        if (success == true) yearlyBackups?.remove(file.year);
        notifyListeners();
      },
    );
  }

  Future<void> sync(BuildContext context) async {
    await context.read<BackupProvider>().recheckAndSync(
      services: [backupProvider.repository.getService(serviceType)],
      context: context,
    );
    await load();
  }

  void signOut(BuildContext context) async {
    await context.read<BackupProvider>().signOut(context, serviceType);
    if (context.mounted) Navigator.maybePop(context);
  }

  /// Shows [SpICloudSettingsSheet] then hands off to Settings, the only real
  /// way to disable iCloud Drive for the app (mirrors `BackupProvider.signIn`'s
  /// "enable" flow, which does the same for the opposite direction).
  /// Deliberately does *not* call [BackupCloudService.signOut] / clear
  /// [ICloudUserStorage]: unlike an explicit Drive/Nextcloud sign-out, this
  /// isn't a confirmed disconnect — the user might cancel in Settings, or
  /// toggle it back on shortly after. Clearing the stored account here would
  /// mean losing the `autoBackupEnabled` preference and misreading a
  /// re-enable as a "new" account. The next live availability check (already
  /// running on every app resume) reflects whatever the user actually did.
  Future<void> disableICloud(BuildContext context) async {
    final service = backupProvider.repository.getService(serviceType);
    if (service is ICloudCloudService) {
      await SpICloudSettingsSheet.show(context, service: service);
    }
  }

  Future<void> retry(BuildContext context) async {
    await load();
  }

  void setAutoBackupEnabled(BuildContext context, bool value) {
    final service = backupProvider.repository.getService(serviceType);
    service.setAutoBackupEnabled(value);
    notifyListeners();
  }

  Future<void> reauthenticate(BuildContext context) async {
    await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#reauthenticate',
      future: () async {
        final service = backupProvider.repository.getService(serviceType);
        await service.reauthenticateIfNeeded();
        await load();
      },
    );
  }

  /// A revoked grant needs fresh user input, not a silent retry: OAuth
  /// re-consent for Drive (same account), or a new app password for
  /// Nextcloud — pre-filled with the server/username that's still known
  /// since a revoked auth no longer wipes the stored account. iCloud has
  /// neither: reconnecting just means re-checking live OS availability
  /// (via BackupProvider.signIn, which shows Settings guidance if it's
  /// still off) rather than any credential flow.
  Future<void> reconnect(BuildContext context) async {
    if (serviceType == BackupServiceType.icloud) {
      await backupProvider.signIn(context, serviceType);
      await load();
    } else if (serviceType == BackupServiceType.nextcloud) {
      final service = backupProvider.repository.getService(serviceType);
      final currentUser = service.currentUser as NextcloudUserObject?;

      final connected = await SpConnectNextcloudSheet(
        initialServerUrl: currentUser?.serverUrl,
        initialUsername: currentUser?.username,
        initialFolderName: currentUser?.folderName,
      ).show<bool>(context: context);

      if (connected != true || !context.mounted) return;

      // A successful connect() only fixes the stored credentials — without
      // this, this service's status in BackupSyncStateStore (driving the
      // sidebar tile and the Data & Backup list) stays stuck on "needs
      // permission" until the next unrelated sync happens to run.
      await MessengerService.of(context).showLoading(
        debugSource: '$runtimeType#reconnect',
        future: () => backupProvider.recheckAndSync(services: [service], context: context),
      );
      await load();
    } else if (serviceType == BackupServiceType.dropbox) {
      // Dropbox's revoked-grant fix is the same interactive OAuth2 flow as a
      // fresh sign-in (there's no separate "re-request scope" concept the
      // way Drive has) — signIn() re-runs the PKCE flow and persists the new
      // tokens itself.
      await backupProvider.signIn(context, serviceType);
      await load();
    } else {
      await backupProvider.requestScope(context, serviceType);
      await load();
    }
  }
}
