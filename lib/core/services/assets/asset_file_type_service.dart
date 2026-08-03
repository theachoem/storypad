import 'package:image_picker/image_picker.dart';
import 'package:storypad/core/helpers/path_helper.dart' as path show extension;

/// Classifies a picked file that could be either an image or a video.
///
/// The native mixed picker hands back both kinds in one list, and two separate
/// steps need to tell them apart: compression at pick time
/// (`AppFilePickerService`) and the `AssetType` chosen at insert time
/// (`InsertFileToDbService.insertMedia`). They must agree, so they share this.
///
/// [isVideoExtension] serves a third caller that has no [XFile] to inspect:
/// `ImportMediaFromTarService`, classifying archive entries by name alone.
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
    return isVideoExtension(path.extension(file.path));
  }

  /// Whether [extension] (with or without a leading dot) names a video file.
  static bool isVideoExtension(String extension) {
    final normalized = extension.toLowerCase();
    return _videoExtensions.contains(normalized.startsWith('.') ? normalized : '.$normalized');
  }
}
