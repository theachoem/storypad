import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/picked_media_object.dart';
import 'package:storypad/core/services/assets/asset_file_type_service.dart';
import 'package:storypad/core/services/assets/video_compression_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/core/types/asset_compression_option.dart';
import 'package:storypad/providers/root_provider.dart';

class AppFilePickerService {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<PickedMediaObject?> pickImage({
    required ImageSource source,
    required AssetCompressionOption compression,
  }) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: compression.imagePickerQuality,
    );
    if (image == null) return null;

    return PickedMediaObject.read(image);
  }

  /// `image_picker` applies the user's [AssetCompressionOption] to images
  /// itself (`imageQuality`) but offers nothing equivalent for video, so the
  /// re-encode is done here instead -- same moment, same setting, so nothing
  /// downstream has to know a video was ever compressed.
  ///
  /// Re-encoding takes seconds on a long clip, which is why the spinner lives
  /// here too rather than at each call site: one that forgot it would just
  /// look frozen. [context] is only used for that -- and only to reach the
  /// root navigator's context, resolved before the picker is opened, so the
  /// spinner survives the caller's own sheet/route going away while picking.
  static Future<PickedMediaObject?> pickVideo({
    required BuildContext context,
    required ImageSource source,
    required AssetCompressionOption compression,
  }) async {
    final rootContext = context.read<RootProvider>().navigatorKey.currentContext;
    final video = await _imagePicker.pickVideo(source: source);
    if (video == null) return null;
    if (rootContext == null || !rootContext.mounted) return _compressAndRead(video, compression);

    final picked = await MessengerService.of(rootContext).showLoading(
      debugSource: 'AppFilePickerService#pickVideo',
      future: () => _compressAndRead(video, compression),
    );

    return picked ?? await PickedMediaObject.read(video);
  }

  static Future<PickedMediaObject> _compressAndRead(XFile video, AssetCompressionOption compression) async {
    return PickedMediaObject.read(await VideoCompressionService.compress(video, compression) ?? video);
  }

  /// Opens the native OS picker for a mixed image+video multi-select
  /// (e.g. the system Photos picker). The result can contain both images and
  /// videos -- callers must classify each file (see `InsertFileToDbService.insertMedia`).
  static Future<List<PickedMediaObject>> pickMultipleMedia({
    required BuildContext context,
    required AssetCompressionOption compression,
  }) async {
    final rootContext = context.read<RootProvider>().navigatorKey.currentContext;
    final files = await _imagePicker.pickMultipleMedia(imageQuality: compression.imagePickerQuality);

    // Skip the spinner entirely for an all-images batch -- nothing to re-encode.
    if (!files.any(AssetFileTypeService.isVideo)) return _readAll(files);
    if (rootContext == null || !rootContext.mounted) return _compressVideosAndRead(files, compression);

    final picked = await MessengerService.of(rootContext).showLoading(
      debugSource: 'AppFilePickerService#pickMultipleMedia',
      future: () => _compressVideosAndRead(files, compression),
    );

    return picked ?? await _readAll(files);
  }

  /// Compresses every video in a mixed batch, leaving images (already
  /// compressed by the picker itself) untouched.
  static Future<List<PickedMediaObject>> _compressVideosAndRead(
    List<XFile> files,
    AssetCompressionOption compression,
  ) async {
    final result = <PickedMediaObject>[];

    for (final file in files) {
      if (!AssetFileTypeService.isVideo(file)) {
        result.add(await PickedMediaObject.read(file));
        continue;
      }

      result.add(await _compressAndRead(file, compression));
    }

    return result;
  }

  static Future<List<PickedMediaObject>> _readAll(List<XFile> files) async {
    final result = <PickedMediaObject>[];
    for (final file in files) {
      result.add(await PickedMediaObject.read(file));
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
