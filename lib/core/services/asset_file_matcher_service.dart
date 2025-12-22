import 'dart:io';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

/// Service for matching orphaned assets with their temporary files.
///
/// Uses creation time proximity to match assets with files:
/// - Assets are created first in the database
/// - Files are created shortly after (usually within seconds)
/// - Matches files to assets by finding the closest preceding file
class AssetFileMatcherService {
  /// Match multiple assets with available temporary files
  ///
  /// Algorithm:
  /// 1. Sort assets by creation time
  /// 2. Sort files by creation time
  /// 3. For each asset, find the closest file created around the same time
  /// 4. Use a time window of ±30 seconds for matching
  static Future<Map<AssetDbModel, File>> matchAssets({
    required List<AssetDbModel> assets,
    required List<File> availableFiles,
  }) async {
    if (assets.isEmpty || availableFiles.isEmpty) return {};

    final Map<AssetDbModel, File> matches = {};

    // Sort assets by creation time
    final sortedAssets = List<AssetDbModel>.from(assets)..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Get file stats and sort by creation time
    final fileStats = await _getFileStats(availableFiles);
    if (fileStats.isEmpty) return {};

    // Match each asset with closest file
    for (final asset in sortedAssets) {
      final match = _findClosestFile(asset, fileStats);
      if (match != null) {
        matches[asset] = match.$1;
        // Remove used file to avoid duplicate matches
        fileStats.remove(match.$1);
        AppLogger.d('✅ Matched asset ${asset.id} with ${match.$1.path} (${match.$2}ms difference)');
      } else {
        AppLogger.d('❌ No match found for asset ${asset.id}');
      }
    }

    return matches;
  }

  /// Get file stats for all files
  static Future<Map<File, FileStat>> _getFileStats(List<File> files) async {
    final Map<File, FileStat> stats = {};

    for (final file in files) {
      try {
        final stat = await file.stat();
        stats[file] = stat;
      } catch (e) {
        AppLogger.d('⚠️ Could not stat file ${file.path}: $e');
      }
    }

    return stats;
  }

  /// Find the closest file to an asset's creation time
  ///
  /// Returns a tuple of (File, timeDifferenceInMs) or null if no match within tolerance
  static (File, int)? _findClosestFile(
    AssetDbModel asset,
    Map<File, FileStat> fileStats,
  ) {
    const int maxToleranceMs = 30000; // 30 seconds
    final assetCreatedAt = asset.createdAt;
    final expectedExt = extension(asset.originalSource);

    File? bestMatch;
    int bestDiff = maxToleranceMs;

    for (final entry in fileStats.entries) {
      final file = entry.key;
      final stat = entry.value;
      final fileExt = extension(file.path);

      // Skip if extension doesn't match
      if (fileExt != expectedExt) continue;

      // Calculate time difference
      final fileCreatedAt = stat.modified;
      final diff = assetCreatedAt.difference(fileCreatedAt).inMilliseconds.abs();

      // Find closest match within tolerance
      if (diff < bestDiff) {
        bestDiff = diff;
        bestMatch = file;
      }
    }

    return bestMatch != null ? (bestMatch, bestDiff) : null;
  }
}
