import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/helpers/path_helper.dart' as path show extension;

/// Classifies a picked file that could be either an image or a video.
///
/// The native mixed picker hands back both kinds in one list, and two separate
/// steps need to tell them apart: compression at pick time
/// (`AppFilePickerService`) and the `AssetType` chosen at insert time
/// (`InsertFileToDbService.insertMedia`). They must agree, so they share this.
class AssetFileTypeService {
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

  static bool isVideo(XFile file) {
    final mimeType = file.mimeType;
    if (mimeType != null) return mimeType.startsWith('video/');
    return _videoExtensions.contains(path.extension(file.path).toLowerCase());
  }
}
