// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:http/http.dart' as http;
import 'package:storypad/core/objects/google_user_object.dart';

class SpDbImageProvider extends ImageProvider<SpDbImageProvider> {
  final String assetLink;
  final double scale;
  final GoogleUserObject? currentUser;

  SpDbImageProvider({
    required this.assetLink,
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
      debugLabel: key.assetLink,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('AssetLink: $assetLink'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    SpDbImageProvider key, {
    required ImageDecoderCallback decode,
  }) async {
    assert(key == this);

    AssetDbModel? asset = await AssetDbModel.findBy(assetLink: assetLink);
    File? localFile = asset?.localFile;

    var uploadedEmails = asset?.getGoogleDriveForEmails() ?? [];
    if (localFile == null && uploadedEmails.isNotEmpty == true && !uploadedEmails.contains(currentUser?.email)) {
      throw StateError('Login with ${asset?.getGoogleDriveForEmails()?.join(" or ")} to see the image.');
    }

    if (currentUser?.email != null && asset?.getGoogleDriveIdForEmail(currentUser!.email) != null) {
      final imageUrl = asset!.getGoogleDriveUrlForEmail(currentUser!.email);
      if (imageUrl == null) throw StateError('$assetLink with $imageUrl cannot be loaded');

      final downloadedFile = File(asset.downloadFilePath);
      if (!downloadedFile.existsSync()) {
        try {
          http.Response? response;
          response = await http.get(
            Uri.parse(imageUrl),
            headers: currentUser?.authHeaders,
          );

          final downloadedFile = File(asset.downloadFilePath);
          await downloadedFile.create(recursive: true);
          await downloadedFile.writeAsBytes(response.bodyBytes);

          localFile = downloadedFile;
        } catch (e) {
          if (e is HttpException && e.message.contains('403')) {
            throw StateError('Sign in with ${currentUser!.email} to see image.');
          }
          rethrow;
        }
      }
    }

    if (localFile != null) {
      return decode(await ui.ImmutableBuffer.fromFilePath(localFile.path));
    } else {
      throw StateError('$assetLink cannot be loaded.');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is SpDbImageProvider &&
        other.assetLink == assetLink &&
        currentUser?.accessToken == other.currentUser?.accessToken &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(assetLink, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'SpDbImageProvider')}("$assetLink", scale: ${scale.toStringAsFixed(1)})';
}
