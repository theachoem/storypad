import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/backup_databases_to_backup_object_service.dart';
import 'package:storypad/views/backup_services/backups/show/show_backup_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:storypad/providers/backup_provider.dart';

import 'import_export_view.dart';

enum AppExportOption {
  storyPadJson,
  markdown,
  pdf,
}

class ImportExportViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ImportExportRoute params;
  final String parentName = "backups";

  ImportExportViewModel({
    required this.params,
  }) {
    loadStoryCount(notifyUI: false);
  }

  int? storyCount;
  SearchFilterObject initialExportFilter = SearchFilterObject(
    years: {},
    types: {},
    tagId: null,
    assetId: null,
  );

  late SearchFilterObject exportFilter = initialExportFilter;

  bool get filtered =>
      jsonEncode(exportFilter.toDatabaseFilter()) != jsonEncode(initialExportFilter.toDatabaseFilter());

  void setExportFilter(SearchFilterObject result) {
    exportFilter = result;
    loadStoryCount(notifyUI: true);
  }

  Future<void> loadStoryCount({
    bool notifyUI = true,
  }) async {
    storyCount = StoryDbModel.db.getStoryCountBy(filters: exportFilter.toDatabaseFilter());
    if (notifyUI) notifyListeners();
  }

  Future<void> import(BuildContext context) async {
    AnalyticsService.instance.logImportOfflineBackup();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (!context.mounted) return;

    final file = result?.files.firstOrNull;
    if (file == null || file.path == null || !file.path!.endsWith(".json")) return;

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
        databases: BackupRepository.databases,
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

      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(
            title: basename(file.path),
            sharePositionOrigin: Rect.fromLTWH(
              0,
              0,
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2,
            ),
            files: [
              XFile(file.path),
            ],
          ),
        );
      }

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
