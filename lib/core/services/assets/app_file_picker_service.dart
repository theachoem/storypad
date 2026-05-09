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

  static Future<FilePickerResult?> pickImageFiles({
    required bool allowMultiple,
    required AssetCompressionOption compression,
    bool withData = true,
  }) {
    return FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: allowMultiple,
      withData: withData,
      compressionQuality: compression.filePickerCompressionQuality,
    );
  }

  static Future<FilePickerResult?> pickAnyFiles({
    FileType type = FileType.any,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
  }) {
    return FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
    );
  }

  static Future<LostDataResponse> retrieveLostData() {
    return _imagePicker.retrieveLostData();
  }
}
