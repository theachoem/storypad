import 'dart:io' show File;
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/objects/picked_media_object.dart';
import 'package:storypad/core/helpers/path_helper.dart' as path show extension;

class InsertFileToDbService {
  /// Generic method for inserting any asset type
  ///
  /// This is the core logic for file insertion, handling:
  /// - Creating directories
  /// - Copying the file to storage
  /// - Cleaning up temporary files
  /// - Creating and saving the AssetDbModel
  ///
  /// The file is always copied from [sourcePath] natively, never buffered --
  /// a few minutes of 4K video is hundreds of MB and the picker can hand over
  /// several at once.
  static Future<AssetDbModel?> _insertAsset({
    required String sourcePath,
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
    File(storagePath).createSync(recursive: true);
    await File(sourcePath).copy(storagePath);

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

  /// [size] is read at pick time (see [PickedMediaObject.read]), not here --
  /// inserting only moves the file into storage.
  static Future<AssetDbModel?> insertImage(
    XFile file, {
    required ui.Size? size,
  }) {
    return _insertAsset(
      sourcePath: file.path,
      assetType: AssetType.image,
      width: size?.width,
      height: size?.height,
    );
  }

  /// See [insertImage] for where [size] comes from.
  static Future<AssetDbModel?> insertVideo(
    XFile file, {
    required ui.Size? size,
  }) {
    return _insertAsset(
      sourcePath: file.path,
      assetType: AssetType.video,
      width: size?.width,
      height: size?.height,
    );
  }

  static Future<AssetDbModel?> insertAudio(
    String filePath, {
    int? durationInMs,
  }) {
    return _insertAsset(
      sourcePath: filePath,
      assetType: AssetType.audio,
      metadata: durationInMs != null ? {AssetDbModel.DURATION_KEY: durationInMs} : null,
    );
  }

  /// Inserts a file picked from a mixed image+video source (e.g. the native
  /// OS media picker), auto-detecting whether it's an image or a video.
  static Future<AssetDbModel?> insertMedia(PickedMediaObject picked) {
    if (picked.isVideo) return insertVideo(picked.file, size: picked.size);
    return insertImage(picked.file, size: picked.size);
  }
}
