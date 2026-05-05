import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/backup_exceptions/backup_exception.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/cloud_optimize/cloud_asset_analyzer.dart';

import 'cloud_optimize_view.dart';

enum OptimizeStep { idle, syncing, fetchingFiles, analyzing, awaitingConfirmation, cleaningUp, done, error }

class DetachedFileResult {
  final CloudFileObject file;
  const DetachedFileResult(this.file);
}

class StaleDuplicateResult {
  final CloudFileObject file;
  const StaleDuplicateResult(this.file);
}

class CloudOptimizeViewModel extends ChangeNotifier with DisposeAwareMixin {
  final CloudOptimizeRoute params;
  final BackupCloudService service;
  final String userIdentifier;

  /// Optional callback invoked during the sync preflight step.
  /// Should trigger sync for signed-in providers and return true only when all requested syncs succeed.
  final Future<bool> Function() syncCallback;

  CloudOptimizeViewModel({
    required this.params,
    required this.service,
    required this.userIdentifier,
    required this.syncCallback,
  }) {
    startOptimize();
  }

  OptimizeStep currentStep = OptimizeStep.idle;
  String? errorMessage;
  bool syncSucceeded = false;

  // Step 2 results (fetch)
  int fetchedFilesCount = 0;

  // Step 3 results (analyze)
  int analyzedCount = 0;

  /// All detached files found during analysis (shown for reference).
  List<DetachedFileResult> detachedFiles = [];

  /// Detached files eligible for trash (age ≥ 30 days).
  List<DetachedFileResult> detachedCandidates = [];

  List<StaleDuplicateResult> staleDuplicates = [];

  // Step 3 results
  int deletedCount = 0;
  int failedCount = 0;

  BackupServiceType get serviceType => service.serviceType;

  bool get hasFindings => detachedCandidates.isNotEmpty || staleDuplicates.isNotEmpty;

  bool get hasFilesToClean => staleDuplicates.isNotEmpty || detachedCandidates.isNotEmpty;

  int get totalToClean => staleDuplicates.length + detachedCandidates.length;

  int get totalBytesToClean {
    int total = 0;
    for (final r in staleDuplicates) {
      total += r.file.sizeInBytes ?? 0;
    }
    for (final r in detachedCandidates) {
      total += r.file.sizeInBytes ?? 0;
    }
    return total;
  }

  Future<void> startOptimize() async {
    // Small delay to ensure the UI has time to render first frame.
    // Why? Because we will call notifyListeners() here & in backup provider as well which will cause throw.
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 1: sync preflight. Detached cleanup is disabled unless this succeeds.
    currentStep = OptimizeStep.syncing;
    notifyListeners();
    FirebaseCrashlytics.instance.log('$runtimeType#startOptimize: syncing latest data');

    try {
      syncSucceeded = await syncCallback();
      FirebaseCrashlytics.instance.log(
        syncSucceeded
            ? '$runtimeType#startOptimize: sync preflight succeeded'
            : '$runtimeType#startOptimize: sync preflight did not complete; detached cleanup disabled',
      );
    } catch (e) {
      FirebaseCrashlytics.instance.log('$runtimeType#startOptimize: sync preflight failed — $e');
      syncSucceeded = false;
    }
    notifyListeners();

    currentStep = OptimizeStep.fetchingFiles;
    notifyListeners();
    FirebaseCrashlytics.instance.log('$runtimeType#startOptimize: fetching cloud files');

    try {
      final allFiles = await _fetchFiles();
      FirebaseCrashlytics.instance.log('$runtimeType#startOptimize: fetched ${allFiles.length} files');

      currentStep = OptimizeStep.analyzing;
      notifyListeners();
      FirebaseCrashlytics.instance.log('$runtimeType#startOptimize: analyzing files');

      await _analyzeFiles(allFiles);
      FirebaseCrashlytics.instance.log(
        '$runtimeType#startOptimize: analysis done — '
        '${staleDuplicates.length} stale, '
        '${detachedCandidates.length} detached candidates '
        '(${detachedFiles.length} detached total)',
      );

      if (!hasFindings) {
        FirebaseCrashlytics.instance.log('$runtimeType#startOptimize: nothing to clean, done');
        currentStep = OptimizeStep.done;
        notifyListeners();
        return;
      }

      currentStep = OptimizeStep.awaitingConfirmation;
      notifyListeners();
      // Wait for user to call startCleanup()
    } catch (e) {
      FirebaseCrashlytics.instance.log('$runtimeType#startOptimize: failed — $e');
      errorMessage = e.toString();
      currentStep = OptimizeStep.error;
      notifyListeners();
    }
  }

  Future<void> startCleanup() async {
    currentStep = OptimizeStep.cleaningUp;
    notifyListeners();
    FirebaseCrashlytics.instance.log('$runtimeType#startCleanup: started — $totalToClean files to trash');

    try {
      await _cleanUpFiles();
      FirebaseCrashlytics.instance.log(
        '$runtimeType#startCleanup: done — $deletedCount trashed, $failedCount failed',
      );
      currentStep = OptimizeStep.done;
      notifyListeners();
    } catch (e) {
      FirebaseCrashlytics.instance.log('$runtimeType#startCleanup: failed — $e');
      errorMessage = e.toString();
      currentStep = OptimizeStep.error;
      if (!disposed) notifyListeners();
    }
  }

  Future<void> retry() async {
    errorMessage = null;
    syncSucceeded = false;
    detachedFiles = [];
    detachedCandidates = [];
    staleDuplicates = [];
    fetchedFilesCount = 0;
    analyzedCount = 0;
    deletedCount = 0;
    failedCount = 0;
    await startOptimize();
  }

  Future<List<CloudFileObject>> _fetchFiles() async {
    final results = await Future.wait([
      service.listFilesInFolder('images'),
      service.listFilesInFolder('audio'),
    ]);

    final allFiles = [...results[0], ...results[1]];

    fetchedFilesCount = allFiles.length;
    notifyListeners();
    return allFiles;
  }

  Future<void> _analyzeFiles(List<CloudFileObject> files) async {
    // Collect parseable asset IDs for the batch DB query
    final Set<int> assetIds = {};
    for (final file in files) {
      final fileName = file.fileName;
      if (fileName == null) continue;
      final assetId = int.tryParse(fileName.split('.').first);
      if (assetId != null) assetIds.add(assetId);
    }

    // Batch-fetch all matching DB records in a single query, including tombstones.
    final allIds = assetIds.toList();
    final collection = allIds.isNotEmpty
        ? await AssetDbModel.db.where(filters: {'ids': allIds}, returnDeleted: true)
        : null;
    final records = collection?.items ?? [];
    final Map<int, AssetDbModel> recordById = {
      for (final r in records)
        if (r.permanentlyDeletedAt == null) r.id: r,
    };
    final Map<int, AssetDbModel> tombstoneById = {
      for (final r in records)
        if (r.permanentlyDeletedAt != null) r.id: r,
    };

    // Delegate pure classification logic to CloudAssetAnalyzer
    final result = CloudAssetAnalyzer.analyze(
      cloudFiles: files,
      recordById: recordById,
      serviceTypeId: serviceType.id,
    );

    analyzedCount = files.length;
    detachedFiles = result.detached.map(DetachedFileResult.new).toList();
    staleDuplicates = result.stale.map(StaleDuplicateResult.new).toList();

    // Detached cleanup is only safe after sync preflight has succeeded.
    detachedCandidates = syncSucceeded
        ? detachedFiles.where((r) {
            final assetId = r.file.fileName != null ? int.tryParse(r.file.fileName!.split('.').first) : null;
            final tombstone = assetId != null ? tombstoneById[assetId] : null;
            return CloudAssetAnalyzer.isDetachedEligibleForCleanup(r.file, tombstone: tombstone);
          }).toList()
        : [];

    notifyListeners();
  }

  Future<void> _cleanUpFiles() async {
    final latestFiles = await _fetchFiles();

    // Refresh records for the current cloud set plus original candidates so final verification sees both
    // the stale candidates and the live copies that make deletion safe.
    final candidateFiles = [
      ...staleDuplicates.map((r) => r.file),
      ...detachedCandidates.map((r) => r.file),
    ];
    final assetIds = _assetIdsFromFiles([...latestFiles, ...candidateFiles]);
    final collection = assetIds.isNotEmpty
        ? await AssetDbModel.db.where(filters: {'ids': assetIds.toList()}, returnDeleted: true)
        : null;
    final records = collection?.items ?? [];
    final Map<int, AssetDbModel> freshRecords = {
      for (final r in records)
        if (r.permanentlyDeletedAt == null) r.id: r,
    };
    final Map<int, AssetDbModel> freshTombstones = {
      for (final r in records)
        if (r.permanentlyDeletedAt != null) r.id: r,
    };

    final verifiedResult = CloudAssetAnalyzer.analyze(
      cloudFiles: latestFiles,
      recordById: freshRecords,
      serviceTypeId: serviceType.id,
    );
    final safeStaleIds = {for (final f in verifiedResult.stale) f.id};

    // Stale duplicates: re-verify before trashing
    for (final file in staleDuplicates.map((r) => r.file)) {
      if (!safeStaleIds.contains(file.id)) {
        FirebaseCrashlytics.instance.log(
          '$runtimeType#_cleanUpFiles: skipping ${file.fileName} — no longer safe to trash',
        );
        failedCount++;
        if (!disposed) notifyListeners();
        continue;
      }

      if (disposed) break;
      await _trashOne(file);
    }

    // Detached candidates: re-apply the sync and age gates with fresh records, then trash
    if (!syncSucceeded) {
      FirebaseCrashlytics.instance.log('$runtimeType#_cleanUpFiles: detached cleanup skipped because sync failed');
      return;
    }

    for (final result in detachedCandidates) {
      if (disposed) break;

      final file = result.file;
      final assetId = file.fileName != null ? int.tryParse(file.fileName!.split('.').first) : null;
      final tombstone = assetId != null ? freshTombstones[assetId] : null;

      if (!CloudAssetAnalyzer.isDetachedEligibleForCleanup(file, tombstone: tombstone)) {
        FirebaseCrashlytics.instance.log(
          '$runtimeType#_cleanUpFiles: ${file.fileName} no longer eligible after re-check',
        );
        failedCount++;
        if (!disposed) notifyListeners();
        continue;
      }

      await _trashOne(file);
    }
  }

  Future<void> _trashOne(CloudFileObject file) async {
    try {
      final success = await service.trashFile(file.id);
      if (success) {
        deletedCount++;
      } else {
        failedCount++;
      }
    } on BackupException catch (e) {
      if (e.toString().toLowerCase().contains('not found')) {
        FirebaseCrashlytics.instance.log('$runtimeType#_trashOne: ${file.fileName} already gone, counting as trashed');
        deletedCount++;
      } else {
        FirebaseCrashlytics.instance.log('$runtimeType#_trashOne: failed — ${file.fileName}: $e');
        failedCount++;
      }
    } catch (e) {
      FirebaseCrashlytics.instance.log('$runtimeType#_trashOne: failed — ${file.fileName}: $e');
      failedCount++;
    }
    if (!disposed) notifyListeners();
  }

  Set<int> _assetIdsFromFiles(List<CloudFileObject> files) {
    final ids = <int>{};
    for (final file in files) {
      final fileName = file.fileName;
      if (fileName == null) continue;
      final id = int.tryParse(fileName.split('.').first);
      if (id != null) ids.add(id);
    }
    return ids;
  }
}
