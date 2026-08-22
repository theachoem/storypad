import 'dart:typed_data';
import 'package:storypad/core/services/cloud_storage/adaptors/cdn_cloud_storage_adaptor.dart';

/// Thrown when download is rejected due to access denial.
class CloudStorageUnauthorizedException implements Exception {
  final String message;

  CloudStorageUnauthorizedException(this.message);
}

abstract class BaseCloudStorageAdaptor {
  static BaseCloudStorageAdaptor create() {
    // CDN base URL can be overridden via --dart-define=CDN_BASE_URL=https://...
    const cdnBaseUrl = String.fromEnvironment('CDN_BASE_URL', defaultValue: 'https://static.storypad.me');
    return CdnCloudStorageAdaptor(baseUrl: cdnBaseUrl);
  }

  /// Download the raw bytes for [hashPath] (e.g. `/relax_sounds/animal/forest_birds-abc123.svg`).
  /// Throws [CloudStorageUnauthorizedException] on access denial.
  Future<Uint8List?> downloadBytes(String hashPath);

  /// Return a publicly accessible URL for [hashPath], or null if unavailable.
  Future<String?> getDownloadUrl(String hashPath);
}
