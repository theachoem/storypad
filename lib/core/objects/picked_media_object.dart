import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:storypad/core/services/assets/asset_file_type_service.dart';

/// A media file that has been picked (and, for video, already compressed),
/// paired with the dimensions read off it right then.
///
/// The size is extracted at pick time -- same moment as compression -- so it
/// describes the file that actually gets stored, and so inserting is left with
/// nothing but the insert itself.
class PickedMediaObject {
  const PickedMediaObject({
    required this.file,
    required this.size,
  });

  final XFile file;
  final ui.Size? size;

  bool get isVideo => AssetFileTypeService.isVideo(file);

  /// Reads [file]'s dimensions once, up front, so tiles and loading
  /// placeholders can size themselves synchronously later (see
  /// `AssetsBox.findAspectRatioSync`) instead of waiting on a decode or a full
  /// player initialization -- no reflow. It also has to happen before the
  /// insert, which moves the file out of its temporary location.
  static Future<PickedMediaObject> read(XFile file) async {
    return PickedMediaObject(
      file: file,
      size: AssetFileTypeService.isVideo(file) ? await _readVideoSize(file) : await _readImageSize(file),
    );
  }

  static Future<ui.Size?> _readImageSize(XFile file) async {
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = await codec.getNextFrame();
      final size = ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      return size;
    } catch (_) {
      return null;
    } finally {
      codec?.dispose();
    }
  }

  static Future<ui.Size?> _readVideoSize(XFile file) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      return controller.value.size;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
  }
}
