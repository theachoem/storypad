import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/services/assets/asset_file_type_service.dart';
import 'package:storypad/core/services/assets/video_compression_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/asset_compression_option.dart';

class AppFilePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<XFile?> pickImage({
    required ImageSource source,
    required AssetCompressionOption compression,
  }) {
    return _imagePicker.pickImage(
      source: source,
      imageQuality: compression.imagePickerQuality,
    );
  }

  /// `image_picker` applies the user's [AssetCompressionOption] to images
  /// itself (`imageQuality`) but offers nothing equivalent for video, so the
  /// re-encode is done here instead -- same moment, same setting, so nothing
  /// downstream has to know a video was ever compressed.
  ///
  /// Re-encoding takes seconds on a long clip, which is why the spinner lives
  /// here too rather than at each call site: one that forgot it would just
  /// look frozen. [context] is only used for that.
  static Future<XFile?> pickVideo({
    required BuildContext context,
    required ImageSource source,
    required AssetCompressionOption compression,
  }) async {
    final video = await _imagePicker.pickVideo(source: source);
    if (video == null) return null;
    if (!context.mounted) return await VideoCompressionService.compress(video, compression) ?? video;

    final compressed = await MessengerService.of(context).showLoading(
      debugSource: 'AppFilePickerService#pickVideo',
      future: () => VideoCompressionService.compress(video, compression),
    );

    return compressed ?? video;
  }

  /// Opens the native OS picker for a mixed image+video multi-select
  /// (e.g. the system Photos picker). The result can contain both images and
  /// videos -- callers must classify each file (see `InsertFileToDbService.insertMedia`).
  static Future<List<XFile>> pickMultipleMedia({
    required BuildContext context,
    required AssetCompressionOption compression,
  }) async {
    final files = await _imagePicker.pickMultipleMedia(imageQuality: compression.imagePickerQuality);

    // Skip the spinner entirely for an all-images batch -- nothing to re-encode.
    if (!files.any(AssetFileTypeService.isVideo)) return files;
    if (!context.mounted) return _compressVideos(files, compression);

    final compressed = await MessengerService.of(context).showLoading(
      debugSource: 'AppFilePickerService#pickMultipleMedia',
      future: () => _compressVideos(files, compression),
    );

    return compressed ?? files;
  }

  /// Compresses every video in a mixed batch, leaving images (already
  /// compressed by the picker itself) untouched.
  static Future<List<XFile>> _compressVideos(List<XFile> files, AssetCompressionOption compression) async {
    final result = <XFile>[];

    for (final file in files) {
      if (!AssetFileTypeService.isVideo(file)) {
        result.add(file);
        continue;
      }

      result.add(await VideoCompressionService.compress(file, compression) ?? file);
    }

    return result;
  }

  static Future<XFile?> pickJsonFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.firstOrNull?.xFile;
  }

  static Future<XFile?> pickGzipFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gz'],
    );
    return result?.files.firstOrNull?.xFile;
  }

  static Future<LostDataResponse> retrieveLostData() {
    return _imagePicker.retrieveLostData();
  }
}
