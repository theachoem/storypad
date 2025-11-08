// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';

class SpDbImageProvider extends ImageProvider<SpDbImageProvider> {
  final String embedLink;
  final double scale;
  final GoogleUserObject? currentUser;

  SpDbImageProvider({
    required this.embedLink,
    required this.currentUser,
    this.scale = 1,
  });

  @override
  Future<SpDbImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SpDbImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(SpDbImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode: decode),
      scale: key.scale,
      debugLabel: key.embedLink,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('AssetLink: $embedLink'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    SpDbImageProvider key, {
    required ImageDecoderCallback decode,
  }) async {
    AssetDbModel? asset = await AssetDbModel.findBy(embedLink: embedLink);
    File? localFile = asset?.localFile;

    try {
      assert(key == this);

      // Download asset if needed
      if (asset != null && localFile == null) {
        final downloader = GoogleDriveAssetDownloaderService();
        localFile = File(
          await downloader.downloadAsset(
            asset: asset,
            currentUser: currentUser,
            localFile: localFile,
          ),
        );
      }

      // Validate content type for images
      if (localFile != null && localFile.existsSync()) {
        final contentType = _getContentType(localFile);
        if (contentType != null && !contentType.startsWith('image/')) {
          throw StateError('Invalid content type: $contentType');
        }
        return decode(await ui.ImmutableBuffer.fromFilePath(localFile.path));
      } else {
        throw StateError('$embedLink cannot be loaded.');
      }
    } catch (e) {
      if (asset != null && File(asset.localFilePath).existsSync()) {
        File(asset.localFilePath).deleteSync();
      }

      rethrow;
    }
  }

  /// Get content type from file extension
  String? _getContentType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const imageExtensions = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
    };
    return imageExtensions[extension];
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is SpDbImageProvider &&
        other.embedLink == embedLink &&
        currentUser?.accessToken == other.currentUser?.accessToken &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(embedLink, currentUser?.email, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'SpDbImageProvider')}("$embedLink", scale: ${scale.toStringAsFixed(1)})';
}
