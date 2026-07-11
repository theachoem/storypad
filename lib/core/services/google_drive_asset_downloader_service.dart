import 'dart:async';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/google_user_object.dart';

class GoogleDriveAssetDownloaderException {
  final String message;
  final StackTrace? stackTrace;

  /// HTTP status code when the failure originated from an HTTP response
  /// (e.g. 401/403 auth, 404 missing). `null` for non-HTTP failures.
  final int? statusCode;

  GoogleDriveAssetDownloaderException(
    this.message, {
    this.stackTrace,
    this.statusCode,
  });

  /// Auth-related failures affect every download for the current session, so
  /// callers should stop rather than retry the remaining assets.
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'GoogleDriveAssetDownloaderException: $message';
}

/// Service for downloading assets from Google Drive with authentication.
///
/// This service provides a reusable pattern for downloading various asset types
/// (audio, images, videos, PDFs, etc.) from Google Drive. It handles:
/// - Local caching
/// - Authentication via Google OAuth
/// - Permission validation
/// - Error handling
///
/// Usage:
/// ```dart
/// final service = GoogleDriveAssetDownloaderService();
/// final filePath = await service.downloadAsset(
///   asset: assetModel,
///   currentUser: googleUser,
///   embedLink: 'gs://bucket/path',
/// );
/// ```
class GoogleDriveAssetDownloaderService {
  static const int maxDownloadSize = 20 * 1024 * 1024; // 20MB

  /// Tracks in-progress downloads by local file path to prevent concurrent downloads
  final Map<String, Completer<String>> _downloadingByPath = {};

  /// Downloads an asset from Google Drive if not already cached locally.
  ///
  /// Returns the local file path if successful.
  /// Throws [GoogleDriveAssetDownloaderException] with a descriptive message if download fails.
  ///
  /// Parameters:
  /// - [asset]: The asset model containing metadata and download URLs
  /// - [currentUser]: The authenticated Google user
  /// - [embedLink]: The asset's firestore storage link (used for error messages)
  /// - [localFile]: Optional cached file - if exists and valid, returns immediately
  ///
  /// Throws:
  /// - [GoogleDriveAssetDownloaderException] if user doesn't have permission to download
  /// - [GoogleDriveAssetDownloaderException] if network request fails
  /// - [GoogleDriveAssetDownloaderException] if file can't be saved locally
  Future<String> downloadAsset({
    required AssetDbModel asset,
    required GoogleUserObject? currentUser,
    File? localFile,
  }) {
    // Check if file already exists locally
    if (localFile != null && localFile.existsSync()) {
      return Future.value(localFile.path);
    }

    final localFilePath = asset.localFilePath;

    // Check if file exists at expected path (even if localFile wasn't provided)
    if (File(localFilePath).existsSync()) {
      return Future.value(localFilePath);
    }

    // If download is already in progress, wait for it
    final inFlight = _downloadingByPath[localFilePath];
    if (inFlight != null && !inFlight.isCompleted) {
      return inFlight.future;
    }

    // Create a new completer for this download. `completer.future` is always
    // returned below so the original caller is guaranteed to be a listener —
    // otherwise `completeError` below has no listener when there's no
    // concurrent waiter, which Dart reports as an unhandled async error even
    // though the caller already receives it via the returned future.
    final completer = Completer<String>();
    _downloadingByPath[localFilePath] = completer;

    _performDownload(
          asset: asset,
          currentUser: currentUser,
          localFilePath: localFilePath,
        )
        .then(completer.complete)
        .catchError((Object e) => completer.completeError(e))
        .whenComplete(() {
          // Clean up the completer after completion to prevent memory leaks
          _downloadingByPath.remove(localFilePath);
        });

    return completer.future;
  }

  Future<String> _performDownload({
    required AssetDbModel asset,
    required GoogleUserObject? currentUser,
    required String localFilePath,
  }) async {
    final uploadedEmails = asset.getGoogleDriveForEmails() ?? [];

    // Check if user has permission to download
    if (uploadedEmails.isNotEmpty && !uploadedEmails.contains(currentUser?.email)) {
      throw GoogleDriveAssetDownloaderException(
        'Login with ${uploadedEmails.join(" or ")} to access this ${asset.type.name}.',
      );
    }

    // If no user or no Google Drive access, can't download
    if (currentUser == null || asset.getGoogleDriveIdForEmail(currentUser.email) == null) {
      throw GoogleDriveAssetDownloaderException('${asset.relativeLocalFilePath} cannot be loaded.');
    }

    // Get download URL from Google Drive
    final downloadUrl = asset.getGoogleDriveUrlForEmail(currentUser.email);
    if (downloadUrl == null) {
      throw GoogleDriveAssetDownloaderException(
        '${asset.relativeLocalFilePath} with no valid download URL cannot be loaded.',
      );
    }

    // Download file from Google Drive
    return _downloadFromUrl(
      downloadUrl: downloadUrl,
      localFilePath: localFilePath,
      authHeaders: currentUser.authHeaders,
      embedLink: asset.relativeLocalFilePath,
    );
  }

  /// Internal method to handle the actual HTTP download and file saving.
  Future<String> _downloadFromUrl({
    required String downloadUrl,
    required String localFilePath,
    required Map<String, String> authHeaders,
    required String embedLink,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: authHeaders,
      );

      // Handle authentication errors
      if (response.statusCode == 401) {
        throw GoogleDriveAssetDownloaderException(
          'Authentication expired. Please sign in again to download this asset.',
          statusCode: 401,
        );
      }

      if (response.statusCode == 403) {
        throw GoogleDriveAssetDownloaderException(
          'Access denied. Please sign in to download this asset.',
          statusCode: 403,
        );
      }

      // Handle other HTTP errors
      if (response.statusCode == 404) {
        FirebaseCrashlytics.instance.log('$runtimeType#_downloadFromUrl: 404 — $embedLink');
        throw GoogleDriveAssetDownloaderException(
          'Asset not found (404). Status: 404',
          statusCode: 404,
        );
      }

      if (response.statusCode != 200) {
        throw GoogleDriveAssetDownloaderException(
          'Failed to download asset. Status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      // Validate file size
      if (response.bodyBytes.length > maxDownloadSize) {
        throw GoogleDriveAssetDownloaderException(
          'Asset is too large (${response.bodyBytes.length ~/ (1024 * 1024)}MB). '
          'Maximum allowed: ${maxDownloadSize ~/ (1024 * 1024)}MB',
        );
      }

      // Save file to local storage using an atomic write: write the full bytes
      // to a temp file first, then rename it into place. rename() is atomic on
      // the same filesystem, so the canonical path only ever appears
      // fully-written — a crash/kill mid-write can't leave a truncated file
      // that would later be counted as "downloaded" and shown as a corrupt image.
      final downloadedFile = File(localFilePath);
      final tempFile = File('$localFilePath.download');

      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(response.bodyBytes, flush: true);
      await tempFile.rename(localFilePath);

      debugPrint('✅ Asset downloaded successfully: $embedLink');
      return downloadedFile.path;
    } catch (e) {
      // Clean up partial downloads (both the temp file and any stale target).
      for (final file in [File('$localFilePath.download'), File(localFilePath)]) {
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (deleteError) {
            debugPrint('⚠️ Failed to clean up partial download: $deleteError');
          }
        }
      }

      debugPrint('❌ Error downloading asset: $e');

      if (e is GoogleDriveAssetDownloaderException) {
        rethrow;
      } else {
        throw GoogleDriveAssetDownloaderException('Failed to download asset: $e');
      }
    }
  }
}
