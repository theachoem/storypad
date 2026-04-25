import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:storypad/core/services/cloud_storage/adaptors/cdn_cloud_storage_adaptor.dart';
import 'package:storypad/core/services/cloud_storage/adaptors/firebase_cloud_storage_adaptor.dart';

/// Thrown when download is rejected due to access denial.
class CloudStorageUnauthorizedException implements Exception {
  final String message;

  CloudStorageUnauthorizedException(this.message);
}

abstract class BaseCloudStorageAdaptor {
  static BaseCloudStorageAdaptor create() {
    // CDN base URL can be provided via --dart-define=CDN_BASE_URL=https://...
    const cdnBaseUrl = String.fromEnvironment('CDN_BASE_URL');
    if (cdnBaseUrl.isNotEmpty) return CdnCloudStorageAdaptor(baseUrl: cdnBaseUrl);

    // On Linux without a CDN URL, cloud assets are unavailable.
    if (!kIsWeb && Platform.isLinux) return _NoopCloudStorageAdaptor();

    return FirebaseCloudStorageAdaptor();
  }

  /// Download the raw bytes for [hashPath] (e.g. `/relax_sounds/animal/forest_birds-abc123.svg`).
  /// Throws [CloudStorageUnauthorizedException] on access denial.
  Future<Uint8List?> downloadBytes(String hashPath);

  /// Return a publicly accessible URL for [hashPath], or null if unavailable.
  Future<String?> getDownloadUrl(String hashPath);
}

/// No-op adaptor used when no cloud storage backend is configured.
class _NoopCloudStorageAdaptor extends BaseCloudStorageAdaptor {
  @override
  Future<Uint8List?> downloadBytes(String hashPath) async => null;

  @override
  Future<String?> getDownloadUrl(String hashPath) async => null;
}
