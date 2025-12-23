import 'dart:io';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/services/logger/app_logger.dart';

/// Service for matching orphaned assets with their temporary files.
///
/// Uses sequential matching based on creation time order:
/// - Assets are created first in the database (when recording starts)
/// - Files are created after recording finishes (can be hours later for long recordings)
/// - Matches files to assets by finding the next available file created after each asset
/// - Works for any recording length without time limits
class AssetFileMatcherService {
  /// Match multiple assets with available temporary files
  ///
  /// Algorithm:
  /// 1. Sort assets by creation time (oldest first)
  /// 2. Sort files by creation time (oldest first)
  /// 3. For each asset, find the first unused file created after it with matching extension
  /// 4. No time limit - handles recordings of any length (seconds to hours)
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

    final sortedFiles = fileStats.entries.toList()..sort((a, b) => a.value.modified.compareTo(b.value.modified));

    // Match each asset with the next available file
    int fileIndex = 0;
    for (final asset in sortedAssets) {
      final match = _findNextFile(asset, sortedFiles, fileIndex);
      if (match != null) {
        matches[asset] = match.$1;
        fileIndex = match.$2 + 1; // Move to next file for next asset
        AppLogger.d('✅ Matched asset ${asset.id} with ${match.$1.path}');
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

  /// Find the next available file created after an asset
  ///
  /// Returns a tuple of (File, fileIndex) or null if no match found
  static (File, int)? _findNextFile(
    AssetDbModel asset,
    List<MapEntry<File, FileStat>> sortedFiles,
    int startIndex,
  ) {
    final assetCreatedAt = asset.createdAt;
    final expectedExt = extension(asset.originalSource);

    // Search for the first file created after the asset with matching extension
    for (int i = startIndex; i < sortedFiles.length; i++) {
      final entry = sortedFiles[i];
      final file = entry.key;
      final stat = entry.value;
      final fileExt = extension(file.path);

      // Skip if extension doesn't match
      if (fileExt != expectedExt) continue;

      // Check if file was created after (or around) the asset
      final fileCreatedAt = stat.modified;
      final diff = fileCreatedAt.difference(assetCreatedAt).inMilliseconds;

      // Allow small negative diff (up to 5 seconds) for timing variations
      if (diff >= -5000) {
        return (file, i);
      }
    }

    return null;
  }
}
