import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/assets/import_media_from_tar_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/support_directory_path.dart';

import 'import_media_overview_view.dart';

/// A resolved entry that pairs a scanned archive entry with the current state
/// of the database and filesystem, so the UI can show the appropriate status.
class ImportMediaEntry {
  const ImportMediaEntry({
    required this.scanEntry,
    required this.existingAsset,
    required this.targetFileExists,
    required this.storyCount,
  });

  final ImportMediaScanEntry scanEntry;
  final AssetDbModel? existingAsset;
  final bool targetFileExists;
  final int storyCount;

  bool get isNew => existingAsset == null;
  bool get isRestore => existingAsset != null && !targetFileExists;
  bool get isSkipped => existingAsset != null && targetFileExists;

  /// The file to use for preview. Prefers the existing on-device file when
  /// available so we display the actual stored copy, not just the archive copy.
  File get previewFile {
    if (existingAsset != null && targetFileExists) {
      return File(existingAsset!.localFilePath);
    }
    return scanEntry.previewFile;
  }
}

class ImportMediaOverviewViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ImportMediaOverviewRoute params;

  ImportMediaOverviewViewModel({
    required this.params,
  }) {
    _load();
  }

  List<ImportMediaEntry>? entries;
  Directory? _tempDir;

  int get toImportCount => entries?.where((e) => !e.isSkipped).length ?? 0;

  Future<void> _load() async {
    final tmpPath = '${SupportDirectoryPath.tmp.directoryPath}/import_preview_${DateTime.now().millisecondsSinceEpoch}';
    _tempDir = Directory(tmpPath);

    try {
      final scanEntries = await ImportMediaFromTarService.scan(
        tarGzStream: File(params.tarFilePath).openRead(),
        tempDir: _tempDir!,
      );

      final assetFutures = scanEntries.map((e) => AssetDbModel.db.find(e.id));
      final assets = await Future.wait(assetFutures);

      final storiesCount = StoryDbModel.db.getStoryCountByAssets(
        assetIds: scanEntries.map((e) => e.id).toList(),
      );

      final resolved = <ImportMediaEntry>[];
      for (var i = 0; i < scanEntries.length; i++) {
        final scan = scanEntries[i];
        final existing = assets[i];
        final targetFileExists = existing != null && File(existing.localFilePath).existsSync();
        resolved.add(
          ImportMediaEntry(
            scanEntry: scan,
            existingAsset: existing,
            targetFileExists: targetFileExists,
            storyCount: storiesCount[scan.id] ?? 0,
          ),
        );
      }

      if (!disposed) {
        entries = resolved;
        notifyListeners();
      }
    } catch (_) {
      if (!disposed) {
        entries = [];
        notifyListeners();
      }
    }
  }

  Future<void> performImport(BuildContext context) async {
    final counts = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#performImport',
      future: () => ImportMediaFromTarService.call(
        tarGzStream: File(params.tarFilePath).openRead(),
        findAsset: (id) => AssetDbModel.db.find(id),
        fileExists: (path) => File(path).existsSync(),
        writeFile: (path, bytesStream) async {
          final f = File(path);
          await f.create(recursive: true);
          final sink = f.openWrite();
          try {
            await sink.addStream(bytesStream);
          } finally {
            await sink.close();
          }
        },
        saveAsset: (asset) async => asset.save(runCallbacks: false),
        getStoragePath: (type, id, ext) => type.getStoragePath(id: id, extension: ext),
        getRelativePath: (type, id, ext) => type.getRelativeStoragePath(id: id, extension: ext),
      ),
    );

    if (!context.mounted) return;

    final imported = counts?.imported ?? 0;
    final skipped = counts?.skipped ?? 0;

    final message = [
      if (imported > 0) '$imported file(s) imported',
      if (skipped > 0) '$skipped already existed',
      if (imported == 0 && skipped == 0) tr("snack_bar.empty_or_invalid_file"),
    ].join('  ·  ');

    MessengerService.of(context).showSnackBar(message, success: imported > 0 || skipped > 0);

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _tempDir?.delete(recursive: true).ignore();
    super.dispose();
  }
}
