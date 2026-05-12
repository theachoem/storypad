import 'dart:async';
import 'dart:io';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';
import 'package:storypad/core/types/asset_type.dart';

/// Shared service for loading asset files with in-memory caching and deduplication.
///
/// Caching strategy:
/// - _inFlightByRelativePath: deduplicate concurrent loads of same path; auto-cleared on completion
/// - _resolvedByRelativePath: cache successful file lookups (LinkedHashMap for FIFO eviction)
/// - Max 100 cached entries; oldest inserted is evicted when limit exceeded (access does not update position)
/// - On failure, in-flight entry is cleared to allow retry on next call
class DbAssetLoaderService {
  DbAssetLoaderService._();

  static final DbAssetLoaderService instance = DbAssetLoaderService._();

  static const int _maxCachedEntries = 100;

  final Map<String, Completer<File>> _inFlightByRelativePath = {};
  final Map<String, File> _resolvedByRelativePath = {};

  /// Load a file by relative path.
  /// Returns cached result if exists and still valid; deduplicates concurrent requests for same path.
  /// On errors, removes in-flight entry to allow retry.
  Future<File> load({
    required String relativePath,
    required GoogleUserObject? currentUser,
  }) {
    // Check if already cached and file still exists on disk
    final cached = _resolvedByRelativePath[relativePath];
    if (cached != null) {
      if (cached.existsSync()) return Future.value(cached);
      _resolvedByRelativePath.remove(relativePath);
    }

    // If already loading this path, return existing in-flight completer (dedupe)
    final inFlight = _inFlightByRelativePath[relativePath];
    if (inFlight != null && !inFlight.isCompleted) return inFlight.future;

    final completer = Completer<File>();
    _inFlightByRelativePath[relativePath] = completer;

    _loadInternal(
          relativePath: relativePath,
          currentUser: currentUser,
        )
        .then((file) {
          _resolvedByRelativePath[relativePath] = file;
          _evictOldestIfNeeded();
          completer.complete(file);
        })
        .catchError((Object error, StackTrace stackTrace) {
          completer.completeError(error, stackTrace);
        })
        .whenComplete(() {
          _inFlightByRelativePath.remove(relativePath);
        });

    return completer.future;
  }

  Future<File> _loadInternal({
    required String relativePath,
    required GoogleUserObject? currentUser,
  }) async {
    int? id = AssetType.parseAssetId(relativePath);
    AssetType? type = AssetType.getTypeFromLink(relativePath);

    if (id == null || type == null) {
      throw GoogleDriveAssetDownloaderException('$relativePath is invalid.');
    }

    String filePath = type.getStoragePath(id: id, extension: extension(relativePath));
    File file = File(filePath);

    if (file.existsSync()) return file;

    AssetDbModel? asset = await AssetDbModel.db.find(id);
    File? localFile = asset?.localFile;

    if (asset != null && localFile == null && currentUser != null) {
      final downloader = GoogleDriveAssetDownloaderService();
      final localFilePath = await downloader.downloadAsset(
        asset: asset,
        currentUser: currentUser,
        localFile: localFile,
      );

      return File(localFilePath);
    }

    if (localFile != null) return localFile;
    throw GoogleDriveAssetDownloaderException('Asset file for $relativePath not found.');
  }

  /// Remove oldest inserted cached entry if max capacity exceeded (FIFO eviction).
  void _evictOldestIfNeeded() {
    if (_resolvedByRelativePath.length > _maxCachedEntries) {
      final oldestKey = _resolvedByRelativePath.keys.first;
      _resolvedByRelativePath.remove(oldestKey);
    }
  }

  /// Clear all cached resolved assets.
  /// Does not affect in-flight downloads—they complete normally.
  /// Call this on logout or database reset to prevent stale cached files.
  void clear() {
    _resolvedByRelativePath.clear();
  }
}
