import 'dart:async';
import 'dart:io' as io;

import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';

/// Thrown for failures specific to *resolving* which service/destination to
/// download an asset from — e.g. no currently-signed-in service actually has
/// it. Failures during the download itself (auth, network, file-not-found)
/// come straight from [BackupCloudService.downloadFileBytes] as whatever
/// `exp.BackupException` subtype that service already throws — not wrapped
/// here, so callers get the same well-typed errors the sync pipeline does.
class BackupAssetDownloadException implements Exception {
  final String message;

  BackupAssetDownloadException(this.message);

  @override
  String toString() => 'BackupAssetDownloadException: $message';
}

/// Downloads an asset's bytes from whichever *currently signed-in* service
/// actually has it, and writes them to [AssetDbModel.localFilePath].
///
/// This is the display-path counterpart to
/// `BackupImagesUploaderService.backfillFromOtherService` (the sync-path
/// version) — both exist because an asset can be uploaded to one service and
/// never downloaded to a given device. A device that only ever connects to
/// Nextcloud (never Drive) still needs to display media imported from a
/// backup created elsewhere, so this can't be Drive-specific the way the
/// old `GoogleDriveAssetDownloaderService` was.
class BackupAssetDownloaderService {
  static const int maxDownloadSize = 20 * 1024 * 1024; // 20MB

  /// Tracks in-progress downloads by local file path to prevent concurrent
  /// duplicate downloads of the same asset.
  final Map<String, Completer<String>> _downloadingByPath = {};

  /// Downloads [asset] if it isn't already available locally.
  ///
  /// Returns the local file path once available. Throws
  /// [BackupAssetDownloadException] if no signed-in service has this asset;
  /// otherwise whatever `exp.BackupException` the owning service's
  /// [BackupCloudService.downloadFileBytes] throws.
  Future<String> downloadAsset({
    required AssetDbModel asset,
    required List<BackupCloudService> signedInServices,
  }) {
    final localFilePath = asset.localFilePath;

    if (io.File(localFilePath).existsSync()) {
      return Future.value(localFilePath);
    }

    final inFlight = _downloadingByPath[localFilePath];
    if (inFlight != null && !inFlight.isCompleted) {
      return inFlight.future;
    }

    // `completer.future` is always returned below so the original caller is
    // guaranteed to be a listener — otherwise `completeError` below has no
    // listener when there's no concurrent waiter, which Dart reports as an
    // unhandled async error even though the caller already receives it via
    // the returned future.
    final completer = Completer<String>();
    _downloadingByPath[localFilePath] = completer;

    _performDownload(
      asset: asset,
      signedInServices: signedInServices,
      localFilePath: localFilePath,
    ).then(completer.complete).catchError((Object e) => completer.completeError(e)).whenComplete(() {
      _downloadingByPath.remove(localFilePath);
    });

    return completer.future;
  }

  Future<String> _performDownload({
    required AssetDbModel asset,
    required List<BackupCloudService> signedInServices,
    required String localFilePath,
  }) async {
    // A destination only counts if it matches the CURRENTLY signed-in
    // account/folder for that service — a stale destination left over from a
    // since-switched account can't be downloaded with today's credentials.
    // Same identity check used when deleting an asset (LibraryViewModel).
    final destination = asset.matchingCloudDestinationFor(signedInServices);

    if (destination == null) {
      throw BackupAssetDownloadException(
        '${asset.relativeLocalFilePath} is not available from any currently connected account.',
      );
    }

    final service = signedInServices.firstWhere((s) => s.serviceType == destination.serviceType);

    final bytes = await service.downloadFileBytes(destination.fileId);
    if (bytes == null) {
      throw BackupAssetDownloadException(
        '${asset.relativeLocalFilePath} could not be downloaded from ${destination.serviceType.displayName}.',
      );
    }

    if (bytes.length > maxDownloadSize) {
      throw BackupAssetDownloadException(
        'Asset is too large (${bytes.length ~/ (1024 * 1024)}MB). '
        'Maximum allowed: ${maxDownloadSize ~/ (1024 * 1024)}MB',
      );
    }

    // Atomic write: write the full bytes to a temp file first, then rename
    // it into place. rename() is atomic on the same filesystem, so the
    // canonical path only ever appears fully-written — a crash/kill
    // mid-write can't leave a truncated file that would later be counted as
    // "downloaded" and shown as a corrupt image. Suffix matches
    // StorageInfoService.downloadTempSuffix, which reclaims orphaned ones.
    final downloadedFile = io.File(localFilePath);
    final tempFile = io.File('$localFilePath.download');

    try {
      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(localFilePath);
    } catch (e) {
      for (final file in [tempFile, downloadedFile]) {
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {
            // Best-effort cleanup — the original failure is what matters.
          }
        }
      }
      rethrow;
    }

    return downloadedFile.path;
  }
}
