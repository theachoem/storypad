import 'dart:io' show File;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
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
  ) {
    return _insertAsset(
      sourcePath: file.path,
      fileBytes: fileBytes,
      assetType: AssetType.image,
    );
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
}
