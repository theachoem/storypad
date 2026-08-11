// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/widgets/asset_db/sp_db_asset_loader.dart';

class SpDbImageProvider extends ImageProvider<SpDbImageProvider> {
  final String relativePath;
  final double scale;
  final List<BackupCloudService> signedInServices;

  SpDbImageProvider({
    required this.relativePath,
    required this.signedInServices,
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
      debugLabel: key.relativePath,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Asset relative path: $relativePath'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    SpDbImageProvider key, {
    required ImageDecoderCallback decode,
  }) async {
    final file = await SpDbAssetLoader.load(relativePath, signedInServices);
    return decode(await ui.ImmutableBuffer.fromFilePath(file.path));
  }

  /// Which account is signed in for each service — not any single account's
  /// token/refresh state, since resolving a destination via
  /// [BackupCloudService.downloadFileBytes] no longer depends on a
  /// caller-held token the way the old raw-HTTP Drive downloader did.
  String get _accountsKey => signedInServices.map((s) => s.currentUser?.destinationKey).join(',');

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is SpDbImageProvider &&
        other.relativePath == relativePath &&
        _accountsKey == other._accountsKey &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(relativePath, _accountsKey, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'SpDbImageProvider')}("$relativePath", scale: ${scale.toStringAsFixed(1)})';
}
