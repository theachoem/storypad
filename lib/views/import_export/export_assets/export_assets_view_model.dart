import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/assets/backup_asset_downloader_service.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
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

  /// Assets that couldn't be included in the last export — either nothing was
  /// available to download (not backed up to any currently signed-in account)
  /// or the download failed (e.g. the remote file is gone — 404). We export
  /// as much as possible and report the rest as skipped.
  final List<AssetDbModel> _skippedAssets = [];

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

  /// Downloads any assets that aren't available locally so they can be exported.
  ///
  /// Individual failures (e.g. a missing file — 404) are skipped and
  /// collected in [_skippedAssets] so we can still "export as much as
  /// possible". Returns `false` only on an auth error, which affects every
  /// remaining download for that service and means the caller should abort;
  /// disposal mid-download is a graceful stop and returns `true`.
  Future<bool> downloadAssets(BuildContext context) async {
    final signedInServices = context.read<BackupProvider>().signedInServices;

    _skippedAssets.clear();

    // Download assets first if needed
    final assetsToDownload = _assets.where((asset) {
      final file = asset.localFile;
      return file == null || !file.existsSync();
    }).toList();

    if (assetsToDownload.isEmpty) return true;

    _isDownloading = true;
    notifyListeners();

    try {
      for (final asset in assetsToDownload) {
        // Stop gracefully if the screen was popped (view model disposed)
        // mid-download. Not a failure — just halt where we are.
        if (disposed) break;

        // Not uploaded to any currently signed-in account — nothing to
        // download. Same identity check as the downloader itself (a
        // destination for a since-switched account doesn't count).
        if (!_hasDownloadableDestination(asset, signedInServices)) {
          _skippedAssets.add(asset);
          continue;
        }

        try {
          await BackupAssetDownloaderService().downloadAsset(asset: asset, signedInServices: signedInServices);
        } catch (e) {
          // Auth errors affect every remaining download from that service —
          // surface and abort rather than skip-and-continue.
          if (e is exp.AuthException) {
            if (context.mounted) MessengerService.of(context).showError(e.userFriendlyMessage);
            return false;
          }

          // Otherwise skip this asset and keep going.
          _skippedAssets.add(asset);
        }

        // Refresh the "downloaded X/Y" progress shown in the UI after each asset.
        notifyListeners();
      }

      return true;
    } finally {
      // Always reset, even on early return/error, so the button doesn't get
      // stuck at "Downloading...".
      _isDownloading = false;
      notifyListeners();
    }
  }

  bool _hasDownloadableDestination(AssetDbModel asset, List<BackupCloudService> signedInServices) {
    return asset.matchingCloudDestinationFor(signedInServices) != null;
  }

  Future<void> exportAssets(BuildContext context) async {
    // Download what we can. Per-asset failures (e.g. 404) are skipped and
    // collected in [_skippedAssets]; only an auth error aborts the whole export.
    final downloaded = await downloadAssets(context);
    if (!downloaded) return;

    // Remove any archives left behind by previously crashed/cancelled exports
    // so the cache doesn't keep growing across attempts.
    await _cleanUpStaleExports();

    if (!context.mounted) return;

    // Proceed with export. The archive is streamed directly from the original
    // asset files on disk (one file at a time) so memory stays flat regardless
    // of how many/large the assets are — see exportAssets crash fix.
    final tarFile = await MessengerService.of(context).showLoading(
      debugSource: '$runtimeType#exportAssets',
      future: () async {
        final String exportFileName =
            "$kAppName-${kDeviceInfo.model}-assets-${DateTime.now().toIso8601String()}.tar.gz";

        final tarFile = File("${SupportDirectoryPath.export_assets.directoryPath}/$exportFileName");
        await tarFile.create(recursive: true);

        Stream<TarEntry> buildEntries() async* {
          for (final asset in _assets) {
            final file = asset.localFile;
            if (file == null || !file.existsSync()) continue;

            yield TarEntry(
              TarHeader(
                name: asset.relativeLocalFilePath, // eg. images/123.jpg
                mode: 420, // 0644 in octal
                size: file.lengthSync(),
                modified: file.lastModifiedSync(),
              ),
              file.openRead(), // lazy disk read — only one file streamed at a time
            );
          }
        }

        await buildEntries().transform(tarWriter).transform(gzip.encoder).pipe(tarFile.openWrite());

        return tarFile;
      },
    );

    if (!context.mounted) return;
    if (tarFile == null) return;

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
      if (await tarFile.exists()) await tarFile.delete();
    }

    // Let the user know some assets couldn't be included in the export.
    if (context.mounted && _skippedAssets.isNotEmpty) {
      MessengerService.of(
        context,
      ).showSnackBar('${_skippedAssets.length} asset(s) were unavailable and skipped from the export.');
    }
  }

  Future<void> _cleanUpStaleExports() async {
    final exportDir = SupportDirectoryPath.export_assets.directory;
    if (await exportDir.exists()) {
      for (final entity in exportDir.listSync()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {
          // best-effort cleanup
        }
      }
    }
  }
}
