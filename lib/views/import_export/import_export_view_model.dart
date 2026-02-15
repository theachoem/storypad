import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/types/support_directory_path.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/widgets/sp_app_lock_wrapper.dart';
import 'package:tar/tar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
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
import 'package:storypad/core/services/export/export_stories_to_markdown_service.dart';
import 'package:storypad/core/services/export/export_stories_to_text_service.dart';

import 'import_export_view.dart';

enum AppExportOption {
  storyPadJson,
  text,
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

    FilePickerResult? result = await SpAppLockWrapper.disableAppLockIfHas(
      context,
      callback: () => FilePicker.platform.pickFiles(type: FileType.any),
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

  Future<void> export(BuildContext context, AppExportOption option) async {
    switch (option) {
      case AppExportOption.storyPadJson:
        await exportJson(context);
        break;
      case AppExportOption.text:
        await exportText(context);
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
    if (!context.read<InAppPurchaseProvider>().markdownExport) return;

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
        Map<int, EventDbModel?> events = {};

        await ExportStoriesToMarkdownService.call(
          stories: stories,
          outputDir: tempDir,
          tagNameGetter: (tagId) async {
            tags[tagId] ??= await TagDbModel.db.find(tagId);
            return tags[tagId]?.title;
          },
          eventTypeGetter: (eventId) async {
            events[eventId] ??= await EventDbModel.db.find(eventId);
            return events[eventId]?.eventType;
          },
        );

        // Create tar.gz archive
        final tarFile = File("${SupportDirectoryPath.backups.directoryPath}/$exportFileName");
        await tarFile.create(recursive: true);

        // Create tar.gz archive from directory
        final entries = <TarEntry>[];

        for (final entity in tempDir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.substring(tempDir.path.length + 1);
            final bytes = await entity.readAsBytes();
            entries.add(
              TarEntry.data(
                TarHeader(
                  name: relativePath,
                  mode: 420, // 0644 in octal
                  size: bytes.length,
                  modified: entity.lastModifiedSync(),
                ),
                bytes,
              ),
            );
          }
        }

        await Stream.fromIterable(entries).transform(tarWriter).transform(gzip.encoder).pipe(tarFile.openWrite());
        return (tarFile, tempDir);
      },
    );

    if (!context.mounted) return;
    if (result == null) return;

    File tarFile = result.$1;
    Directory tempDir = result.$2;

    // Share/save the tar.gz file
    if (Platform.isIOS) {
      RenderBox? box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: basename(tarFile.path),
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          files: [XFile(tarFile.path)],
        ),
      );
    } else if (Platform.isAndroid) {
      await FilePicker.platform.saveFile(
        fileName: basename(tarFile.path),
        type: FileType.custom,
        allowedExtensions: ['gz'],
        bytes: await tarFile.readAsBytes(),
      );
    }

    // Cleanup
    await tempDir.delete(recursive: true);
    await tarFile.delete();
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
        Map<int, EventDbModel?> events = {};

        await ExportStoriesToTextService.call(
          stories: stories,
          outputFile: textFile,
          tagNameGetter: (tagId) async {
            tags[tagId] ??= await TagDbModel.db.find(tagId);
            return tags[tagId]?.title;
          },
          eventTypeGetter: (eventId) async {
            events[eventId] ??= await EventDbModel.db.find(eventId);
            return events[eventId]?.eventType;
          },
        );

        return textFile;
      },
    );

    if (!context.mounted) return;
    if (result == null) return;

    // Share/save the text file
    if (Platform.isIOS) {
      RenderBox? box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: basename(result.path),
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          files: [XFile(result.path)],
        ),
      );
    } else if (Platform.isAndroid) {
      await FilePicker.platform.saveFile(
        fileName: basename(result.path),
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: await result.readAsBytes(),
      );
    }

    // Cleanup
    await result.delete();
  }

  Future<void> exportJson(BuildContext context) async {
    AnalyticsService.instance.logExportOfflineBackup();

    DateTime? lastDbUpdatedAt = context.read<BackupProvider>().lastDbUpdatedAt;
    if (lastDbUpdatedAt == null) return;

    final String exportFileName = "$kAppName-${kDeviceInfo.model}-backup-${DateTime.now().toIso8601String()}.json";

    final backup = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#export',
      future: () => BackupDatabasesToBackupObjectService.call(
        databases: BackupRepository.databases,
        storyFilter: filtered ? exportFilter : null,
        lastUpdatedAt: lastDbUpdatedAt,
      ),
    );

    if (backup == null || !context.mounted) return;
    if (Platform.isIOS) {
      final file = File("${SupportDirectoryPath.backups.directoryPath}/$exportFileName");

      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(backup.toContents()));

      await FilePicker.platform.saveFile(
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
