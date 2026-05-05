import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';

/// Classification result for a single cloud file.
enum CloudFileClassification {
  /// The cloud file is pointed to by at least one stored destination — keep it.
  clean,

  /// No local DB record exists for the parsed asset ID — the file is orphaned.
  detached,

  /// A record exists but no stored destination points to this cloud file.
  /// A live copy (pointed to by a destination) was confirmed in the fetched set,
  /// so this file is safe to delete.
  stale,

  /// Filename could not be parsed as an asset ID — classification is skipped.
  unparseable,
}

class CloudFileResult {
  final CloudFileObject file;
  final CloudFileClassification classification;

  const CloudFileResult({required this.file, required this.classification});
}

class CloudAssetAnalysisResult {
  final List<CloudFileObject> detached;
  final List<CloudFileObject> stale;
  final List<CloudFileObject> clean;

  const CloudAssetAnalysisResult({
    required this.detached,
    required this.stale,
    required this.clean,
  });
}

/// Pure analysis service — no DB or network I/O.
///
/// Call [analyze] with:
/// - [cloudFiles]  : all files fetched from the cloud folder
/// - [recordById]  : pre-fetched DB records keyed by asset ID
/// - [serviceTypeId]: e.g. `BackupServiceType.google_drive.id`
///
/// The caller (ViewModel) is responsible for fetching DB records.
class CloudAssetAnalyzer {
  const CloudAssetAnalyzer._();

  /// Returns true if a detached cloud file is old enough to be safely trashed.
  ///
  /// A file is eligible when:
  ///   1. Its [CloudFileObject.createdAt] is non-null and older than [gracePeriod].
  ///   2. If a [tombstone] (soft-deleted DB record) is provided, its
  ///      `permanentlyDeletedAt` is also older than [gracePeriod].
  ///
  /// The 30-day default gives other devices ample time to sync their local
  /// records before we remove the cloud copy.
  static bool isDetachedEligibleForCleanup(
    CloudFileObject file, {
    AssetDbModel? tombstone,
    Duration gracePeriod = const Duration(days: 30),
  }) {
    final fileCreatedAt = file.createdAt?.toUtc();
    if (fileCreatedAt == null) return false;

    final cutoff = DateTime.now().toUtc().subtract(gracePeriod);
    if (!fileCreatedAt.isBefore(cutoff)) return false;

    final fileNameCreatedAt = _createdAtFromFileName(file.fileName);
    if (fileNameCreatedAt != null && !fileNameCreatedAt.isBefore(cutoff)) return false;

    if (tombstone != null) {
      final deletedAt = tombstone.permanentlyDeletedAt?.toUtc();
      if (deletedAt == null) return false;
      if (!deletedAt.isBefore(cutoff)) return false;
    }

    return true;
  }

  static DateTime? _createdAtFromFileName(String? fileName) {
    if (fileName == null) return null;

    final assetId = int.tryParse(fileName.split('.').first);
    if (assetId == null) return null;

    final now = DateTime.now().toUtc();
    final plausibleLowerBound = DateTime(2000).toUtc().millisecondsSinceEpoch;
    final plausibleUpperBound = now.add(const Duration(days: 365)).millisecondsSinceEpoch;
    if (assetId < plausibleLowerBound || assetId > plausibleUpperBound) return null;

    return DateTime.fromMillisecondsSinceEpoch(assetId, isUtc: true);
  }

  static CloudAssetAnalysisResult analyze({
    required List<CloudFileObject> cloudFiles,
    required Map<int, AssetDbModel> recordById,
    required String serviceTypeId,
  }) {
    // Group all cloud files by parsed asset ID so duplicates are handled together.
    final Map<int, List<CloudFileObject>> filesByAssetId = {};

    for (final file in cloudFiles) {
      final fileName = file.fileName;
      if (fileName == null) {
        continue;
      }
      final assetId = int.tryParse(fileName.split('.').first);
      if (assetId != null) {
        filesByAssetId.putIfAbsent(assetId, () => []).add(file);
      }
    }

    // Build a set of every cloud file ID in the fetched batch for O(1) lookups.
    final Set<String> fetchedIds = {for (final f in cloudFiles) f.id};

    final List<CloudFileObject> detached = [];
    final List<CloudFileObject> stale = [];
    final List<CloudFileObject> clean = [];

    for (final entry in filesByAssetId.entries) {
      final assetId = entry.key;
      final group = entry.value;
      final record = recordById[assetId];

      if (record == null) {
        // No local record — every cloud file for this ID is detached.
        detached.addAll(group);
        continue;
      }

      final destinations = record.cloudDestinations[serviceTypeId];

      // Before flagging anything as stale, confirm a live copy exists in the
      // fetched set (safety guard — avoids deleting the last surviving copy).
      final hasLiveCopy =
          destinations?.values.any((d) {
            final storedId = d['file_id'];
            return storedId != null && fetchedIds.contains(storedId);
          }) ==
          true;

      for (final file in group) {
        final isAttached = destinations?.values.any((d) => d['file_id'] == file.id) == true;

        if (isAttached) {
          clean.add(file);
        } else if (hasLiveCopy) {
          stale.add(file);
        } else {
          // Record exists but we can't confirm the correct copy — leave alone.
          clean.add(file);
        }
      }
    }

    return CloudAssetAnalysisResult(
      detached: detached,
      stale: stale,
      clean: clean,
    );
  }
}
