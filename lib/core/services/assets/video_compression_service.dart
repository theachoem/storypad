import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/types/asset_compression_option.dart';

/// Re-encodes a picked/recorded video so a long clip straight off the camera
/// doesn't land in the DB (and later Google Drive) at its original bitrate.
///
/// Images get this from `image_picker`'s `imageQuality`; video has no such
/// picker option, so this stands in for it -- called from the same place, at
/// pick time (`AppFilePickerService`), so nothing downstream has to know a
/// video was ever compressed.
class VideoCompressionService {
  /// Returns the compressed file, or `null` when the caller should keep the
  /// original -- unsupported platform, compression turned off, or the attempt
  /// failed / saved nothing.
  ///
  /// Deletes [file] once it has a smaller replacement to hand back, so the
  /// picker's temp copy doesn't linger; on every other path [file] is left alone.
  ///
  /// Never throws: compression is an optimization, so any failure has to
  /// degrade into "keep what the user picked", not into a lost recording.
  static Future<XFile?> compress(XFile file, AssetCompressionOption compression) async {
    if (!kSupportVideoCompression) return null;

    final quality = _quality(compression);
    if (quality == null) return null;

    // The plugin allows exactly one compression at a time and throws otherwise.
    // Pickers run sequentially, so this only trips if something re-enters.
    if (VideoCompress.isCompressing) return null;

    try {
      final originalSize = await file.length();

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: quality,
        // Deleted below instead, and only once we're sure we're keeping the result.
        deleteOrigin: false,
        includeAudio: true,
      );

      final compressedPath = info?.path;
      if (compressedPath == null || info?.isCancel == true) return null;

      final compressedFile = File(compressedPath);
      if (!compressedFile.existsSync()) return null;

      final compressedSize = compressedFile.lengthSync();

      // Re-encoding an already-compact clip can come out *larger* than the
      // source; keep the original rather than storing the worse file.
      if (compressedSize >= originalSize) {
        compressedFile.deleteSync();
        return null;
      }

      AppLogger.info('VideoCompressionService#compress: $originalSize -> $compressedSize bytes');
      if (File(file.path).existsSync()) File(file.path).deleteSync();

      return XFile(compressedPath);
    } catch (e, s) {
      AppLogger.error('VideoCompressionService#compress error: $e', stackTrace: s);
      return null;
    }
  }

  static VideoQuality? _quality(AssetCompressionOption compression) {
    switch (compression) {
      case AssetCompressionOption.none:
        return null;
      case AssetCompressionOption.standard:
        return VideoQuality.MediumQuality;
    }
  }
}
