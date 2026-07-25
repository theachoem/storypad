import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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

  static Future<XFile?> pickVideo({
    required ImageSource source,
  }) {
    return _imagePicker.pickVideo(source: source);
  }

  /// Opens the native OS picker for a mixed image+video multi-select
  /// (e.g. the system Photos picker). The result can contain both images and
  /// videos -- callers must classify each file (see `InsertFileToDbService.insertMedia`).
  static Future<List<XFile>> pickMultipleMedia({
    required AssetCompressionOption compression,
  }) {
    return _imagePicker.pickMultipleMedia(imageQuality: compression.imagePickerQuality);
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
