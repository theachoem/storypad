import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart' as path show extension;

class InsertFileToDbService {
  /// Generic method for inserting any asset type
  ///
  /// This is the core logic for file insertion, handling:
  /// - Creating directories
  /// - Writing file bytes to disk
  /// - Cleaning up temporary files
  /// - Creating and saving the AssetDbModel
  static Future<AssetDbModel?> _insertAsset({
    required String sourcePath,
    required Uint8List fileBytes,
    required AssetType assetType,
    Map<String, dynamic>? metadata,
    double? width,
    double? height,
  }) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch;
    final extension = path.extension(sourcePath);
    final storagePath = assetType.getStoragePath(id: id, extension: extension);

    // Write file to storage
    final newFile = File(storagePath)..createSync(recursive: true);
    await newFile.writeAsBytes(fileBytes);

    // Clean up temporary source file
    if (File(sourcePath).existsSync()) File(sourcePath).deleteSync(recursive: true);

    // Create asset model
    var asset = AssetDbModel.fromLocalPath(
      id: id,
      localPath: storagePath,
      type: assetType,
      width: width,
      height: height,
    );

    // Apply additional metadata if provided
    if (metadata != null) {
      asset = asset.copyWith(metadata: metadata);
    }

    return asset.save();
  }

  static Future<AssetDbModel?> insertImage(
    XFile file,
    Uint8List fileBytes,
  ) async {
    final size = await _extractImageSize(fileBytes);

    return _insertAsset(
      sourcePath: file.path,
      fileBytes: fileBytes,
      assetType: AssetType.image,
      width: size?.width,
      height: size?.height,
    );
  }

  /// Reads the image's decoded dimensions once at insert time -- even though
  /// `Image` can compute its own size once decoded, this lets loading
  /// placeholders (and the quill "max size" single-embed layout, which gives
  /// no fixed height) size correctly immediately via
  /// `AssetsBox.findAspectRatioSync`, no reflow.
  static Future<ui.Size?> _extractImageSize(Uint8List fileBytes) async {
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(fileBytes);
      final frame = await codec.getNextFrame();
      final size = ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      return size;
    } catch (_) {
      return null;
    } finally {
      codec?.dispose();
    }
  }

  static Future<AssetDbModel?> insertAudio(
    String filePath,
    Uint8List fileBytes, {
    int? durationInMs,
  }) {
    return _insertAsset(
      sourcePath: filePath,
      fileBytes: fileBytes,
      assetType: AssetType.audio,
      metadata: durationInMs != null ? {AssetDbModel.DURATION_KEY: durationInMs} : null,
    );
  }

  static Future<AssetDbModel?> insertVideo(
    XFile file,
    Uint8List fileBytes,
  ) async {
    // Extracted from the original (pre-move) file, since `_insertAsset` deletes it after copying.
    final size = await _extractVideoSize(file);

    return _insertAsset(
      sourcePath: file.path,
      fileBytes: fileBytes,
      assetType: AssetType.video,
      width: size?.width,
      height: size?.height,
    );
  }

  /// Reads the video's dimensions once at insert time so tiles can size
  /// themselves synchronously later without waiting on a full player
  /// initialization (see `AssetsBox.findAspectRatioSync`).
  static Future<ui.Size?> _extractVideoSize(XFile file) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      return controller.value.size;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  static const Set<String> _videoExtensions = {
    '.mp4',
    '.mov',
    '.m4v',
    '.avi',
    '.mkv',
    '.webm',
    '.3gp',
    '.wmv',
    '.flv',
  };

  static bool _looksLikeVideo(XFile file) {
    final mimeType = file.mimeType;
    if (mimeType != null) return mimeType.startsWith('video/');
    return _videoExtensions.contains(path.extension(file.path).toLowerCase());
  }

  /// Inserts a file picked from a mixed image+video source (e.g. the native
  /// OS media picker), auto-detecting whether it's an image or a video.
  static Future<AssetDbModel?> insertMedia(
    XFile file,
    Uint8List fileBytes,
  ) {
    return _looksLikeVideo(file) ? insertVideo(file, fileBytes) : insertImage(file, fileBytes);
  }
}
