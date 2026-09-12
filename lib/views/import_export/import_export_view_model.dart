import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/types/support_directory_path.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:tar/tar.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/repositories/backup_repository.dart';
import 'package:storypad/core/services/backups/sync_steps/utils/backup_databases_to_backup_object_service.dart';
import 'package:storypad/core/services/assets/app_file_picker_service.dart';
import 'package:storypad/views/backup_services/backups/show/show_backup_view.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/core/services/export/export_stories_to_csv_service.dart';
import 'package:storypad/core/services/export/export_stories_to_markdown_service.dart';
import 'package:storypad/core/services/export/export_stories_to_text_service.dart';

import 'import_export_view.dart';
import 'import_media_overview/import_media_overview_view.dart';

enum AppExportOption {
  storyPadJson,
  text,
  csv,
  markdown,
  pdf,
}

class ImportExportViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ImportExportRoute params;

  ImportExportViewModel({
    required this.params,
  }) {
    loadStoryCount(notifyUI: false);
  }

  int? storyCount;
  SearchFilterObject initialExportFilter = SearchFilterObject(
    years: {},
    types: {},
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

    XFile? file = await SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () => AppFilePickerService.pickJsonFile(),
    );

    if (!context.mounted) return;

    if (file == null || !file.path.endsWith('.json')) return;

    final backup = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#import',
      future: () => Isolate.run(() async {
        final jsonString = await file.readAsString();
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

  Future<void> importMedia(BuildContext context) async {
    XFile? file = await SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () => AppFilePickerService.pickGzipFile(),
    );

    if (!context.mounted) return;

    if (file == null) return;

    final path = file.path;
    if (!path.endsWith('.tar.gz') && !path.endsWith('.gz')) {
      MessengerService.of(context).showSnackBar(tr("snack_bar.empty_or_invalid_file"), success: false);
      return;
    }

    if (!context.mounted) return;
    ImportMediaOverviewRoute(tarFilePath: path).push(context);
  }

  Future<void> export(BuildContext context, AppExportOption option) async {
    switch (option) {
      case AppExportOption.storyPadJson:
        await exportJson(context);
        break;
      case AppExportOption.text:
        await exportText(context);
        break;
      case AppExportOption.csv:
        await exportCsv(context);
        break;
      case AppExportOption.markdown:
        await exportMarkdown(context);
        break;
      case AppExportOption.pdf:
        MessengerService.of(context).showSnackBar('PDF export coming soon!');
        break;
    }
  }

  Future<void> exportMarkdown(BuildContext context) async {
    if (!context.read<InAppPurchaseProvider>().isProUser) return;

    AnalyticsService.instance.logExportOfflineBackup();

    (File, Directory)? result = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#exportMarkdown',
      future: () async {
        final stories = await StoryDbModel.db
            .where(filters: filtered ? exportFilter.toDatabaseFilter() : null)
            .then((context) => context?.items);

        if (!context.mounted || stories == null || stories.isEmpty) return null;

        final String exportFileName =
            "$kAppName-${kDeviceInfo.model}-markdown-${DateTime.now().toIso8601String()}.tar.gz";
        final tempDir = Directory(
          "${SupportDirectoryPath.backups.directoryPath}/markdown_export_${DateTime.now().millisecondsSinceEpoch}",
        );

        await tempDir.create(recursive: true);

        // Export stories to markdown (organized by year)
        Map<int, TagDbModel?> tags = {};

        await ExportStoriesToMarkdownService.call(
          stories: stories,
          outputDir: tempDir,
          tagNameGetter: (tagId) async {
            tags[tagId] ??= await TagDbModel.db.find(tagId);
            return tags[tagId]?.title;
          },
        );

        // Create tar.gz archive
        final tarFile = File("${SupportDirectoryPath.backups.directoryPath}/$exportFileName");
        await tarFile.create(recursive: true);

        // Stream each file from the temp directory into the archive (one file
        // at a time) instead of buffering them all in memory — avoids OOM
        // crashes on large exports.
        Stream<TarEntry> buildEntries() async* {
          for (final entity in tempDir.listSync(recursive: true)) {
            if (entity is File) {
              final relativePath = entity.path.substring(tempDir.path.length + 1);
              yield TarEntry(
                TarHeader(
                  name: relativePath,
                  mode: 420, // 0644 in octal
                  size: entity.lengthSync(),
                  modified: entity.lastModifiedSync(),
                ),
                entity.openRead(), // lazy disk read
              );
            }
          }
        }

        await buildEntries().transform(tarWriter).transform(gzip.encoder).pipe(tarFile.openWrite());
        return (tarFile, tempDir);
      },
    );

    if (!context.mounted) return;
    if (result == null) return;

    File tarFile = result.$1;
    Directory tempDir = result.$2;

    try {
      // Share/save the tar.gz file by path (no in-memory copy of the archive).
      // On Android the share sheet still offers "Save to Files/Drive".
      RenderBox? box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: basename(tarFile.path),
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          files: [XFile(tarFile.path)],
        ),
      );
    } finally {
      // Always clean up, even if sharing throws.
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
      if (await tarFile.exists()) await tarFile.delete();
    }
  }

  Future<void> exportText(BuildContext context) async {
    AnalyticsService.instance.logExportOfflineBackup();

    File? result = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#exportText',
      future: () async {
        final stories = await StoryDbModel.db
            .where(filters: filtered ? exportFilter.toDatabaseFilter() : null)
            .then((context) => context?.items);

        if (!context.mounted || stories == null || stories.isEmpty) return null;

        final String exportFileName = "$kAppName-${kDeviceInfo.model}-text-${DateTime.now().toIso8601String()}.txt";
        final textFile = File("${SupportDirectoryPath.backups.directoryPath}/$exportFileName");

        // Export stories to text
        Map<int, TagDbModel?> tags = {};
        await ExportStoriesToTextService.call(
          stories: stories,
          outputFile: textFile,
          tagNameGetter: (tagId) async {
            tags[tagId] ??= await TagDbModel.db.find(tagId);
            return tags[tagId]?.title;
          },
        );

        return textFile;
      },
    );

    if (!context.mounted) return;
    if (result == null) return;

    // Share/save the text file
    if (Platform.isIOS || Platform.isMacOS) {
      RenderBox? box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: basename(result.path),
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          files: [XFile(result.path)],
        ),
      );
    } else if (Platform.isAndroid) {
      await FilePicker.saveFile(
        fileName: basename(result.path),
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: await result.readAsBytes(),
      );
    }

    // Cleanup
    await result.delete();
  }

  Future<void> exportCsv(BuildContext context) async {
    if (!context.read<InAppPurchaseProvider>().isProUser) return;

    AnalyticsService.instance.logExportOfflineBackup();

    File? result = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#exportCsv',
      future: () async {
        final stories = await StoryDbModel.db
            .where(filters: filtered ? exportFilter.toDatabaseFilter() : null)
            .then((context) => context?.items);

        if (!context.mounted || stories == null || stories.isEmpty) return null;

        final String exportFileName = "$kAppName-${kDeviceInfo.model}-csv-${DateTime.now().toIso8601String()}.csv";
        final csvFile = File("${SupportDirectoryPath.backups.directoryPath}/$exportFileName");

        // Export stories to csv
        Map<int, TagDbModel?> tags = {};
        await ExportStoriesToCsvService.call(
          stories: stories,
          outputFile: csvFile,
          tagNameGetter: (tagId) async {
            tags[tagId] ??= await TagDbModel.db.find(tagId);
            return tags[tagId]?.title;
          },
        );

        return csvFile;
      },
    );

    if (!context.mounted) return;
    if (result == null) return;

    // Share/save the csv file
    if (Platform.isIOS || Platform.isMacOS) {
      RenderBox? box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: basename(result.path),
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          files: [XFile(result.path)],
        ),
      );
    } else if (Platform.isAndroid) {
      await FilePicker.saveFile(
        fileName: basename(result.path),
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: await result.readAsBytes(),
      );
    }

    // Cleanup
    await result.delete();
  }

  Future<void> exportJson(BuildContext context) async {
    AnalyticsService.instance.logExportOfflineBackup();

    // lastDbUpdatedAt is only populated after a DB write or a cloud sync run this
    // session, so it can legitimately still be null here (e.g. fresh session, no
    // sync configured). It's only used as the backup's "created at" metadata, so
    // falling back to now() is safe — don't reintroduce a null-guard early return.
    DateTime lastDbUpdatedAt = context.read<BackupProvider>().lastDbUpdatedAt ?? DateTime.now();

    final String exportFileName = "$kAppName-${kDeviceInfo.model}-backup-${DateTime.now().toIso8601String()}.json";

    final backup = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#export',
      future: () => BackupDatabasesToBackupObjectService.call(
        databases: BackupRepository.databases,
        storyFilter: filtered ? exportFilter : null,
        lastUpdatedAt: lastDbUpdatedAt,
        hasCompression: false,
      ),
    );

    if (backup == null || !context.mounted) return;
    if (Platform.isIOS || Platform.isMacOS) {
      final file = File("${SupportDirectoryPath.backups.directoryPath}/$exportFileName");

      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(backup.toContents()));

      await FilePicker.saveFile(
        fileName: exportFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: file.readAsBytesSync(),
      );

      if (context.mounted) {
        RenderBox? box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            title: basename(file.path),
            sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
            files: [
              XFile(file.path),
            ],
          ),
        );
      }

      await file.delete();
    } else if (Platform.isAndroid) {
      await FilePicker.saveFile(
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
