import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/types/support_directory_path.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:tar/tar.dart';

// ignore: depend_on_referenced_packages
import 'package:path/path.dart' show basename;

import 'export_assets_view.dart';

class ExportAssetsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ExportAssetsRoute params;

  ExportAssetsViewModel({
    required this.params,
  }) {
    _loadAssets();
  }

  List<AssetDbModel> _assets = [];

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  Map<AssetType, int> get assetCountsByType {
    final counts = <AssetType, int>{};
    for (final type in AssetType.values) {
      counts[type] = _assets.where((asset) => asset.type == type).length;
    }
    return counts;
  }

  Map<AssetType, int> get downloadedCountsByType {
    final counts = <AssetType, int>{};
    for (final type in AssetType.values) {
      counts[type] = _assets.where((asset) {
        if (asset.type != type) return false;
        final file = asset.localFile;
        return file != null && file.existsSync();
      }).length;
    }
    return counts;
  }

  Future<void> _loadAssets() async {
    final result = await AssetDbModel.db.where();
    _assets = result?.items ?? [];
    notifyListeners();
  }

  Future<void> downloadAssets(BuildContext context) async {
    final currentUser = context.read<BackupProvider>().currentUser;

    // Download assets first if needed
    final assetsToDownload = _assets.where((asset) {
      final file = asset.localFile;
      return file == null || !file.existsSync();
    }).toList();

    if (assetsToDownload.isNotEmpty) {
      _isDownloading = true;
      notifyListeners();

      for (int i = 0; i < assetsToDownload.length; i++) {
        final asset = assetsToDownload[i];
        notifyListeners();

        // Ignore files not uploaded to Google Drive
        if (currentUser == null || !asset.isGoogleDriveUploadedFor(currentUser.email)) {
          continue;
        }

        try {
          await GoogleDriveAssetDownloaderService().downloadAsset(asset: asset, currentUser: currentUser);
        } catch (e) {
          if (context.mounted) {
            MessengerService.of(context).showError('${asset.relativeLocalFilePath}: ${e.toString()}');
          }
          return;
        }
      }

      _isDownloading = false;
      notifyListeners();

      if (!context.mounted) return;
    }
  }

  Future<void> exportAssets(BuildContext context) async {
    await downloadAssets(context);
    if (!context.mounted) return;

    // Proceed with export
    final result = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#exportAssets',
      future: () async {
        final String exportFileName =
            "$kAppName-${kDeviceInfo.model}-assets-${DateTime.now().toIso8601String()}.tar.gz";
        final tempDir = Directory(
          '${SupportDirectoryPath.tmp.directoryPath}/assets_export_${DateTime.now().millisecondsSinceEpoch}',
        );

        await tempDir.create(recursive: true);

        // Copy all downloaded assets to temp directory
        for (final asset in _assets) {
          final sourceFile = asset.localFile;
          if (sourceFile != null && sourceFile.existsSync()) {
            final destFile = File('${tempDir.path}/${asset.relativeLocalFilePath}');
            await destFile.create(recursive: true);
            await sourceFile.copy(destFile.path);
          }
        }

        // Create tar.gz archive
        final tarFile = File("${SupportDirectoryPath.export_assets.directoryPath}/$exportFileName");
        await tarFile.create(recursive: true);

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

    final tarFile = result.$1;
    final tempDir = result.$2;

    // Share/save the tar.gz file
    if (Platform.isIOS) {
      await SharePlus.instance.share(
        ShareParams(
          title: basename(tarFile.path),
          sharePositionOrigin: Rect.fromLTWH(
            0,
            0,
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height / 2,
          ),
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
}
