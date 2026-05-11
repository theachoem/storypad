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

  static Future<List<XFile>> pickImageFiles({
    required bool allowMultiple,
    required AssetCompressionOption compression,
  }) async {
    if (allowMultiple) {
      return _imagePicker.pickMultiImage(imageQuality: compression.imagePickerQuality);
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: compression.imagePickerQuality,
    );

    return image == null ? <XFile>[] : <XFile>[image];
  }

  static Future<XFile?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.firstOrNull?.xFile;
  }

  static Future<XFile?> pickGzipFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gz'],
    );
    return result?.files.firstOrNull?.xFile;
  }

  static Future<LostDataResponse> retrieveLostData() {
    return _imagePicker.retrieveLostData();
  }
}
