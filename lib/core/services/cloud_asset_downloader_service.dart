import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/cloud_service_user.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/objects/web_dev_user_object.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';

/// Generic service for downloading assets from any cloud provider.
///
/// This service abstracts the download logic across multiple cloud providers:
/// - Google Drive
/// - WebDAV
/// - (Future providers can be added here)
///
/// Usage:
/// ```dart
/// final service = CloudAssetDownloaderService();
/// final filePath = await service.downloadAsset(
///   asset: assetModel,
///   availableUsers: [googleUser, webDavUser],
/// );
/// ```
class CloudAssetDownloaderService {
  static const int maxDownloadSize = 20 * 1024 * 1024; // 20MB

  /// Downloads an asset using any available cloud provider.
  ///
  /// Returns the local file path if successful.
  /// Throws [StateError] with a descriptive message if download fails.
  ///
  /// Parameters:
  /// - [asset]: The asset model containing metadata and cloud destinations
  /// - [availableUsers]: List of authenticated users from different cloud services
  /// - [localFile]: Optional cached file - if exists and valid, returns immediately
  Future<String> downloadAsset({
    required AssetDbModel asset,
    required List<CloudServiceUser> availableUsers,
    File? localFile,
  }) async {
    // Check if file already exists locally
    if (localFile != null && localFile.existsSync()) {
      return localFile.path;
    }

    // Try each cloud service until one succeeds
    for (final user in availableUsers) {
      final downloadUrl = _getDownloadUrlForUser(asset, user);

      if (downloadUrl != null) {
        try {
          return _downloadFromUrl(
            downloadUrl: downloadUrl,
            localFilePath: asset.localFilePath,
            authHeaders: _getAuthHeaders(user),
            embedLink: asset.embedLink,
          );
        } catch (e) {
          debugPrint('⚠️ Failed to download from ${user.runtimeType}: $e');
          // Continue to next provider
          continue;
        }
      }
    }

    // If we get here, no provider could download the asset
    throw StateError(_buildErrorMessage(asset, availableUsers));
  }

  /// Get download URL for a specific user/service
  String? _getDownloadUrlForUser(AssetDbModel asset, CloudServiceUser user) {
    if (user is GoogleUserObject) {
      return asset.getGoogleDriveUrlForEmail(user.email);
    } else if (user is WebDevUserObject) {
      final fileId = asset.cloudDestinations[BackupServiceType.web_dav.id]?[user.identifier]?['file_id'];
      if (fileId != null) {
        return '${user.serverUrl}/webdav/StoryPad/assets/$fileId';
      }
    }
    return null;
  }

  /// Get authentication headers for a specific user/service
  Map<String, String> _getAuthHeaders(CloudServiceUser user) {
    if (user is GoogleUserObject) {
      return user.authHeaders;
    } else if (user is WebDevUserObject) {
      final credentials = base64.encode(utf8.encode('${user.username}:${user.password}'));
      return {'Authorization': 'Basic $credentials'};
    }
    return {};
  }

  /// Build a helpful error message based on available providers
  String _buildErrorMessage(AssetDbModel asset, List<CloudServiceUser> availableUsers) {
    final googleEmails = asset.getGoogleDriveForEmails() ?? [];
    final webDavUsers = asset.cloudDestinations[BackupServiceType.web_dav.id]?.keys.toList() ?? [];

    final allRequiredUsers = [...googleEmails, ...webDavUsers];

    if (allRequiredUsers.isEmpty) {
      return '${asset.embedLink} is not uploaded to any cloud service.';
    }

    final hasGoogleDrive = googleEmails.isNotEmpty;
    final hasWebDav = webDavUsers.isNotEmpty;

    if (hasGoogleDrive && hasWebDav) {
      return 'Sign in with ${googleEmails.join(" or ")} (Google Drive) or connect to WebDAV to access this ${asset.type.name}.';
    } else if (hasGoogleDrive) {
      return 'Sign in with ${googleEmails.join(" or ")} to access this ${asset.type.name}.';
    } else {
      return 'Connect to WebDAV to access this ${asset.type.name}.';
    }
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
