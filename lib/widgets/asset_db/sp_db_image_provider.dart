// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:storypad/core/objects/google_user_object.dart';
import 'package:storypad/widgets/asset_db/sp_db_asset_loader.dart';

class SpDbImageProvider extends ImageProvider<SpDbImageProvider> {
  final String relativePath;
  final double scale;
  final GoogleUserObject? currentUser;

  SpDbImageProvider({
    required this.relativePath,
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
    final file = await SpDbAssetLoader.load(relativePath, currentUser);
    return decode(await ui.ImmutableBuffer.fromFilePath(file.path));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is SpDbImageProvider &&
        other.relativePath == relativePath &&
        currentUser?.accessToken == other.currentUser?.accessToken &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(relativePath, currentUser?.email, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'SpDbImageProvider')}("$relativePath", scale: ${scale.toStringAsFixed(1)})';
}
