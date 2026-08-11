import 'dart:io' as io;

import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart' as exp;
import 'package:storypad/core/services/backups/sync_steps/backup_sync_messenger.dart';
import 'package:storypad/core/services/backups/sync_steps/sync_step.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

/// Outcome of trying to source an asset's bytes from another connected
/// service before uploading it onward.
enum BackfillOutcome {
  /// Bytes were fetched and written to local disk successfully.
  succeeded,

  /// No source had it, or the download failed transiently — an ordinary,
  /// unremarkable skip.
  skipped,

  /// The source's copy is confirmed gone (404) — its stale cloudDestinations
  /// entry was cleared so this won't be retried again.
  sourceMissing,
}

class BackupImagesUploaderService {
  BackupImagesUploaderService({required BackupSyncMessenger messenger}) : _messenger = messenger;

  final BackupSyncMessenger _messenger;

  Future<bool> start(
    BackupCloudService cloudService, {
    required bool uploadAssets,
    List<BackupCloudService> allServices = const [],
  }) async {
    AppLogger.d('🚧 $runtimeType#start ...');

    try {
      return await _start(cloudService, uploadAssets: uploadAssets, allServices: allServices);
    } on exp.AuthException catch (e) {
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: false,
        message: e.userFriendlyMessage,
      );
      rethrow; // Let repository handle auth exceptions
    } on exp.NetworkException catch (e) {
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: false,
        message: e.userFriendlyMessage,
      );
      return false;
    } on exp.BackupException catch (e) {
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: false,
        message: e.userFriendlyMessage,
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.d('$runtimeType#start unexpected error: $e $stackTrace');
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: false,
        message: 'Failed to upload images due to unexpected error.',
      );
      return false;
    }
  }

  Future<bool> _start(
    BackupCloudService cloudService, {
    required bool uploadAssets,
    required List<BackupCloudService> allServices,
  }) async {
    if (!cloudService.isSignedIn) {
      throw exp.AuthException(
        'Service ${cloudService.serviceType.displayName} is not signed in',
        exp.AuthExceptionType.signInRequired,
        serviceType: cloudService.serviceType,
      );
    }

    // Deferring media is a success, not a failure: BackupRepository#sync aborts
    // the entire run if this step reports failure, and the rest of the backup
    // (entries, tags, everything text) must still go through. The deferred
    // assets stay in pendingAssets and upload themselves on the next
    // unmetered run — cloudDestinations is the pending queue.
    if (!uploadAssets) {
      // The count is cosmetic, so it must never be able to fail this step —
      // a throw here would abort the entire backup over a status message.
      int? pendingCount;
      try {
        pendingCount = (await pendingAssets(cloudService, allServices: allServices)).length;
      } catch (e) {
        AppLogger.d('$runtimeType: could not count pending assets: $e');
      }

      AppLogger.d('$runtimeType: deferring ${pendingCount ?? 'unknown'} asset(s) — media sync is limited to Wi-Fi.');

      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: true,
        message: switch (pendingCount) {
          0 => 'No media files to be uploaded.',
          null => 'Media uploads are waiting for Wi-Fi.',
          _ => '$pendingCount media file(s) waiting for Wi-Fi.',
        },
      );

      return true;
    }

    final result = await _uploadAssetsForService(cloudService, allServices);

    if (result.storageFull) {
      // Still a success, not a failure — same precedent as the Wi-Fi-only
      // deferral above: steps 2-4 (entries/tags/text) must run regardless of
      // a media-only problem, but the message needs to say what's actually
      // wrong instead of a plain count. Takes precedence over missingCount
      // below since it's the one problem the user can actually act on.
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: true,
        message: result.uploadedCount > 0
            ? '${result.uploadedCount} media file(s) uploaded; ran out of storage space for the rest — free up space and sync again.'
            : 'Not enough storage space to back up media — free up space and sync again.',
      );
    } else if (result.missingCount > 0) {
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: true,
        message: result.uploadedCount > 0
            ? '${result.uploadedCount} media file(s) uploaded; ${result.missingCount} file(s) could not be found '
                  'on their original source and were dropped from the backup record.'
            : '${result.missingCount} file(s) could not be found on their original source and were dropped from '
                  'the backup record.',
      );
    } else if (result.uploadedCount > 0) {
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: true,
        message: '${result.uploadedCount} media file(s) uploaded successfully.',
      );
    } else {
      _messenger.report(
        serviceType: cloudService.serviceType,
        step: SyncStep.uploadAssets,
        processing: false,
        success: true,
        message: 'No media files to be uploaded.',
      );
    }

    return result.uploadedCount >= 0;
  }

  /// Upload all local assets that haven't been backed up to this service.
  ///
  /// Once a backfill hits [exp.ServiceExceptionType.localStorageFull], every
  /// *remaining* backfill this run would fail identically (the disk doesn't
  /// get less full between assets), so further backfill attempts stop —
  /// but assets that are already local need no new write, so they keep
  /// uploading normally regardless.
  Future<({int uploadedCount, bool storageFull, int missingCount})> _uploadAssetsForService(
    BackupCloudService cloudService,
    List<BackupCloudService> allServices,
  ) async {
    final List<AssetDbModel>? localAssets = await _getLocalAsset(cloudService, allServices);

    if (localAssets == null || localAssets.isEmpty) {
      return (uploadedCount: 0, storageFull: false, missingCount: 0);
    }

    _messenger.report(
      serviceType: cloudService.serviceType,
      step: SyncStep.uploadAssets,
      processing: true,
      success: null,
      message: null,
    );

    int uploadedCount = 0;
    int missingCount = 0;
    bool storageFull = false;

    for (AssetDbModel asset in localAssets) {
      if (storageFull && asset.localFile == null) continue;

      try {
        final result = await _uploadAsset(cloudService, asset, allServices);
        if (result.uploaded) uploadedCount++;
        if (result.sourceMissing) missingCount++;
      } on exp.ServiceException catch (e) {
        if (e.type != exp.ServiceExceptionType.localStorageFull) rethrow;
        storageFull = true;
      }
    }

    return (uploadedCount: uploadedCount, storageFull: storageFull, missingCount: missingCount);
  }

  /// Upload a single asset to the specified service with retry logic.
  /// Backfills the asset from another connected service first if it's not
  /// on local disk yet (e.g. uploaded to Drive from another device, never
  /// opened here) — otherwise it would stay invisible to this service forever.
  Future<({bool uploaded, bool sourceMissing})> _uploadAsset(
    BackupCloudService cloudService,
    AssetDbModel asset,
    List<BackupCloudService> allServices,
  ) async {
    if (asset.localFile == null) {
      final outcome = await backfillFromOtherService(asset, allServices, cloudService);
      if (outcome != BackfillOutcome.succeeded) {
        return (uploaded: false, sourceMissing: outcome == BackfillOutcome.sourceMissing);
      }
    }

    final cloudFileName = asset.cloudFileName;

    if (cloudFileName == null || asset.localFile == null) {
      AppLogger.d('Skipping asset upload: missing required data');
      return (uploaded: false, sourceMissing: false);
    }

    try {
      final cloudFile = await RetryExecutor.execute(
        () => cloudService.uploadFile(
          cloudFileName,
          asset.localFile!,
          folderName: asset.type.subDirectory.relativePath,
        ),

        // Asset create is non-idempotent: retrying can create duplicate Drive files.
        policy: RetryPolicy.none,
        operationName: 'upload_asset_$cloudFileName',
      );

      if (cloudFile != null) {
        if (cloudService.currentUser?.destinationKey != null) {
          final updated = asset.copyWithCloudFile(
            serviceType: cloudService.serviceType,
            cloudFile: cloudFile,
            email: cloudService.currentUser!.destinationKey,
          );
          await AssetDbModel.db.set(updated);
        }

        AppLogger.d('Uploaded asset to ${cloudService.serviceType.displayName}: $cloudFileName');
        return (uploaded: true, sourceMissing: false);
      }

      return (uploaded: false, sourceMissing: false);
    } on exp.AuthException catch (e) {
      // Add service type to auth exception
      throw exp.AuthException(
        e.message,
        e.type,
        serviceType: cloudService.serviceType,
        context: e.context,
      );
    } catch (e) {
      AppLogger.d('Failed to upload asset $cloudFileName: $e');
      // Don't rethrow - continue with other assets
      return (uploaded: false, sourceMissing: false);
    }
  }

  /// The first other signed-in service (besides [target]) that already has
  /// this asset, per its own `cloudDestinations` entry — or null if none do.
  BackupCloudService? findBackfillSource(
    AssetDbModel asset,
    List<BackupCloudService> allServices,
    BackupCloudService target,
  ) {
    for (final service in allServices) {
      if (service.serviceType == target.serviceType) continue;

      final destinationKey = service.currentUser?.destinationKey;
      if (destinationKey == null) continue;

      final fileId = asset.cloudFileIdFor(serviceType: service.serviceType, identifier: destinationKey);
      if (fileId != null) return service;
    }

    return null;
  }

  /// Downloads the asset's bytes from whichever other connected service
  /// already has it and writes them to [AssetDbModel.localFilePath]. Since
  /// [AssetDbModel.localFile]/[AssetDbModel.cloudFileName] are computed from
  /// that path rather than cached, the rest of the upload flow picks up the
  /// now-present file with no further changes.
  ///
  /// Returns [BackfillOutcome.skipped] if no source has it, or the download
  /// fails transiently — an ordinary skip, same contract as a plain missing
  /// local file. Returns [BackfillOutcome.sourceMissing] (after clearing the
  /// stale `cloudDestinations` entry) if the source confirms via a 404 that
  /// its copy is actually gone — otherwise this would retry the same
  /// permanent failure (with backoff — see [RetryPolicy.network]) every
  /// sync run, forever. Throws [exp.ServiceException] with
  /// [exp.ServiceExceptionType.localStorageFull] if the *write* fails
  /// instead — that's the device's own disk being full, not a per-asset
  /// problem, so the caller needs to know.
  Future<BackfillOutcome> backfillFromOtherService(
    AssetDbModel asset,
    List<BackupCloudService> allServices,
    BackupCloudService target,
  ) async {
    final source = findBackfillSource(asset, allServices, target);
    if (source == null) return BackfillOutcome.skipped;

    final destinationKey = source.currentUser?.destinationKey;
    final fileId = destinationKey != null
        ? asset.cloudFileIdFor(serviceType: source.serviceType, identifier: destinationKey)
        : null;
    if (fileId == null) return BackfillOutcome.skipped;

    List<int>? bytes;
    try {
      bytes = await RetryExecutor.execute(
        () => source.downloadFileBytes(fileId),
        policy: RetryPolicy.network,
        operationName: 'backfill_asset_${asset.id}_from_${source.serviceType.id}',
      );
    } on exp.FileOperationException catch (e) {
      if (e.statusCode != 404) {
        AppLogger.d('Failed to backfill asset ${asset.id} from ${source.serviceType.displayName}: $e');
        return BackfillOutcome.skipped;
      }

      AppLogger.d(
        'Backfill source ${source.serviceType.displayName} no longer has asset ${asset.id} (404) '
        '— clearing the stale cloudDestinations entry.',
      );
      try {
        final healed = asset.copyWithoutCloudFile(serviceType: source.serviceType, identifier: destinationKey!);
        await AssetDbModel.db.set(healed);
      } catch (persistError) {
        // The 404 is real regardless of whether the cleanup itself could be
        // persisted — a DB hiccup here must not escalate into failing the
        // whole step (same "cosmetic must never fail this" contract as
        // pendingAssets' count above).
        AppLogger.d('Failed to persist stale cloudDestinations cleanup for asset ${asset.id}: $persistError');
      }
      return BackfillOutcome.sourceMissing;
    } catch (e) {
      AppLogger.d('Failed to backfill asset ${asset.id} from ${source.serviceType.displayName}: $e');
      return BackfillOutcome.skipped;
    }
    if (bytes == null) return BackfillOutcome.skipped;

    // A write failure here (unlike a download failure above) means the
    // *device* is out of room — every remaining backfill this run will fail
    // the same way, so this must propagate rather than be swallowed as a
    // per-asset skip.
    try {
      final file = io.File(asset.localFilePath);
      await file.parent.create(recursive: true);

      // Write to a temp path and rename into place only once the write is
      // fully flushed — writing directly to the final path would leave a
      // truncated/empty file there if the write failed partway, and the
      // next sync's `localFile` check would treat that as a valid asset
      // and upload the corrupted bytes onward.
      final tempFile = io.File('${file.path}.part');
      try {
        await tempFile.writeAsBytes(bytes, flush: true);
        await tempFile.rename(file.path);
      } catch (e) {
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {
            // Best-effort cleanup — the write/rename failure below is what
            // actually matters and must still propagate.
          }
        }
        rethrow;
      }
    } on io.FileSystemException catch (e) {
      throw exp.ServiceException(
        'Not enough local storage to backfill asset ${asset.id}: $e',
        exp.ServiceExceptionType.localStorageFull,
        context: 'backfill_asset_${asset.id}',
        serviceType: target.serviceType,
      );
    }

    AppLogger.d('Backfilled asset ${asset.id} from ${source.serviceType.displayName}');
    return BackfillOutcome.succeeded;
  }

  /// Get all local assets that haven't been backed up to this service
  ///
  /// Filters assets where:
  /// - cloudDestinations doesn't have this service, OR
  /// - cloudDestinations[service][email] is null
  /// - Local file exists
  ///
  /// Returns: List of assets needing backup
  Future<List<AssetDbModel>?> _getLocalAsset(
    BackupCloudService cloudService,
    List<BackupCloudService> allServices,
  ) async {
    if (cloudService.currentUser?.destinationKey == null) {
      return (await AssetDbModel.db.where())?.items;
    }

    return pendingAssets(cloudService, allServices: allServices);
  }

  /// Assets that still need uploading to [cloudService] — the single definition
  /// of "not yet backed up", shared with the UI's pending-media count so the two
  /// can never disagree.
  ///
  /// There is no separate queue: an asset is pending precisely while its
  /// cloudDestinations entry for this service+account is missing, which is why
  /// skipping an upload needs no bookkeeping to resume later. An asset missing
  /// locally but backfillable from another service in [allServices] still
  /// counts as pending — it just needs a hop through [backfillFromOtherService]
  /// before it can actually upload.
  Future<List<AssetDbModel>> pendingAssets(
    BackupCloudService cloudService, {
    List<BackupCloudService> allServices = const [],
  }) async {
    final destinationKey = cloudService.currentUser?.destinationKey;
    if (destinationKey == null) return [];

    CollectionDbModel<AssetDbModel>? assets = await AssetDbModel.db.where();

    return assets?.items
            .where(
              (e) =>
                  e.cloudDestinations[cloudService.serviceType.id] == null ||
                  e.cloudDestinations[cloudService.serviceType.id]?[destinationKey] == null,
            )
            .where(
              (e) => e.localFile?.existsSync() == true || findBackfillSource(e, allServices, cloudService) != null,
            )
            .toList() ??
        [];
  }
}
