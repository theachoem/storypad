import 'dart:io';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/google_user_object.dart';

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

  /// Downloads an asset from Google Drive if not already cached locally.
  ///
  /// Returns the local file path if successful.
  /// Throws [StateError] with a descriptive message if download fails.
  ///
  /// Parameters:
  /// - [asset]: The asset model containing metadata and download URLs
  /// - [currentUser]: The authenticated Google user
  /// - [embedLink]: The asset's firestore storage link (used for error messages)
  /// - [localFile]: Optional cached file - if exists and valid, returns immediately
  ///
  /// Throws:
  /// - [StateError] if user doesn't have permission to download
  /// - [StateError] if network request fails
  /// - [StateError] if file can't be saved locally
  Future<String> downloadAsset({
    required AssetDbModel asset,
    required GoogleUserObject? currentUser,
    File? localFile,
  }) async {
    // Check if file already exists locally
    if (localFile != null && localFile.existsSync()) {
      return localFile.path;
    }

    final uploadedEmails = asset.getGoogleDriveForEmails() ?? [];

    // Check if user has permission to download
    if (uploadedEmails.isNotEmpty && !uploadedEmails.contains(currentUser?.email)) {
      throw StateError(
        'Login with ${uploadedEmails.join(" or ")} to access this ${asset.type.name}.',
      );
    }

    // If no user or no Google Drive access, can't download
    if (currentUser == null || asset.getGoogleDriveIdForEmail(currentUser.email) == null) {
      throw StateError('${asset.embedLink} cannot be loaded.');
    }

    // Get download URL from Google Drive
    final downloadUrl = asset.getGoogleDriveUrlForEmail(currentUser.email);
    if (downloadUrl == null) {
      throw StateError('${asset.embedLink} with no valid download URL cannot be loaded.');
    }

    // Download file from Google Drive
    return _downloadFromUrl(
      downloadUrl: downloadUrl,
      localFilePath: asset.localFilePath,
      authHeaders: currentUser.authHeaders,
      embedLink: asset.embedLink,
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
      if (response.statusCode == 403) {
        throw StateError('Access denied. Please sign in to download this asset.');
      }

      // Handle other HTTP errors
      if (response.statusCode != 200) {
        throw StateError(
          'Failed to download asset. Status: ${response.statusCode}',
        );
      }

      // Validate file size
      if (response.bodyBytes.length > maxDownloadSize) {
        throw StateError(
          'Asset is too large (${response.bodyBytes.length ~/ (1024 * 1024)}MB). '
          'Maximum allowed: ${maxDownloadSize ~/ (1024 * 1024)}MB',
        );
      }

      // Save file to local storage
      final downloadedFile = File(localFilePath);
      await downloadedFile.create(recursive: true);
      await downloadedFile.writeAsBytes(response.bodyBytes);

      debugPrint('✅ Asset downloaded successfully: $embedLink');
      return downloadedFile.path;
    } catch (e) {
      // Clean up partial downloads
      final downloadedFile = File(localFilePath);
      if (downloadedFile.existsSync()) {
        try {
          downloadedFile.deleteSync();
        } catch (deleteError) {
          debugPrint('⚠️ Failed to clean up partial download: $deleteError');
        }
      }

      debugPrint('❌ Error downloading asset: $e');
      rethrow;
    }
  }
}
