import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:video_compressor_plus/video_compressor_plus.dart';
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
  /// Resolution cap we ask for, mirroring what `VideoQuality.Res1920x1080Quality`
  /// means on each backend (`AVAssetExportPreset1920x1080` /
  /// `DefaultVideoStrategy.atMost(1080, 1920)`).
  static const int _targetMinorSide = 1080;
  static const int _targetMajorSide = 1920;

  /// The bitrate Android's transcoder derives for a given output size
  /// (`BitRates.estimateVideoBitRate`: `0.14 * w * h * fps`). `MediaInfo` carries
  /// no frame rate, so 30 stands in -- a 60fps source is estimated low, which only
  /// makes the skip below more conservative.
  static const double _bitsPerPixelPerSecond = 0.14;
  static const int _assumedFrameRate = 30;

  /// A re-encode costs seconds of the user's time, so it has to buy a real
  /// saving -- shaving 10% off a clip isn't a trade they'd take.
  static const double _worthCompressingRatio = 1.3;

  /// Returns the compressed file, or `null` when the caller should keep the
  /// original -- unsupported platform, compression turned off, a source already
  /// within target, or the attempt failed / saved nothing.
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

      if (await _alreadyWithinTarget(file.path, originalSize)) {
        AppLogger.info('VideoCompressionService#compress: skipped, $originalSize bytes already within target');
        return null;
      }

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

  /// `true` when re-encoding [path] can only cost time -- it already fits the
  /// resolution cap and is already at or under the bitrate we'd target.
  ///
  /// Anything unknown returns `false`, so a failed probe degrades into the old
  /// behaviour (compress, then let the size guard decide) rather than into no
  /// compression at all. The try/catch is this method's own rather than the
  /// caller's for the same reason: `compress`'s would skip the whole re-encode.
  static Future<bool> _alreadyWithinTarget(String path, int originalSize) async {
    try {
      final info = await VideoCompress.getMediaInfo(path);

      final width = info.width;
      final height = info.height;
      final durationMs = info.duration;
      if (width == null || height == null || durationMs == null) return false;
      if (width <= 0 || height <= 0 || durationMs <= 0) return false;

      // Minor/major rather than width/height: resizing preserves aspect ratio, and
      // the two plugins read orientation from different metadata.
      if (min(width, height) > _targetMinorSide) return false;
      if (max(width, height) > _targetMajorSide) return false;

      // [originalSize] (a real `File.length()`) rather than `info.filesize` -- on
      // iOS that field is `track.totalSampleDataLength`, the video track alone, so
      // it under-reports and would make clips look more compact than they are.
      final sourceBitrate = originalSize * 8 / (durationMs / 1000);
      final targetBitrate = _bitsPerPixelPerSecond * width * height * _assumedFrameRate;

      return sourceBitrate <= targetBitrate * _worthCompressingRatio;
    } catch (e, s) {
      AppLogger.error('VideoCompressionService#_alreadyWithinTarget error: $e', stackTrace: s);
      return false;
    }
  }

  /// `Res1920x1080Quality` is the only member that caps resolution at 1080p on
  /// *both* backends without also collapsing the bitrate. The friendlier-sounding
  /// ones don't do what they say: `MediumQuality` and `DefaultQuality` both resolve
  /// to `AVAssetExportPresetMediumQuality` on iOS/macOS -- a fixed ~360p/~0.7Mbps
  /// target that ignores the source, which is what used to make videos look blurry
  /// -- and `HighestQuality` skips resizing entirely on Android. Don't "simplify"
  /// this back to a nicer name.
  static VideoQuality? _quality(AssetCompressionOption compression) {
    switch (compression) {
      case AssetCompressionOption.none:
        return null;
      case AssetCompressionOption.standard:
        return VideoQuality.Res1920x1080Quality;
    }
  }
}
