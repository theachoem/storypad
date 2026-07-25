import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

enum SpAddMediaAction {
  selectFromLibrary,
  selectFromPhotos,
  takePhoto,
  recordVideo,
  recordVoiceNote,
}

/// Single entry point for adding any media to an entry: picks between the
/// in-app asset library, the native OS photo/video picker, camera capture
/// (photo or video), and voice recording. Returns the chosen action (or null
/// if dismissed) for the caller to act on -- this sheet doesn't know about
/// the rich text editor itself, it's just a menu.
class SpAddMediaActionSheet extends BaseBottomSheet {
  const SpAddMediaActionSheet({this.showRecordVoiceNote = true});

  // Callers that only collect image/video (e.g. SpAlbumManagementSheet) have
  // nowhere to put a voice note, so they hide this tile rather than showing
  // an action that can't be handled.
  final bool showRecordVoiceNote;

  @override
  bool get fullScreen => false;

  static Future<SpAddMediaAction?> pick({
    required BuildContext context,
    bool showRecordVoiceNote = true,
  }) {
    return SpAddMediaActionSheet(showRecordVoiceNote: showRecordVoiceNote).show<SpAddMediaAction>(context: context);
  }

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          _buildTile(
            context,
            icon: SpIcons.photo,
            label: tr('button.select_from_library'),
            action: .selectFromLibrary,
          ),
          _buildTile(
            context,
            icon: SpIcons.addPhoto,
            label: tr('button.select_from_photos'),
            action: .selectFromPhotos,
          ),
          if (kSupportCamera)
            _buildTile(
              context,
              icon: SpIcons.camera,
              label: tr('button.take_photo'),
              action: .takePhoto,
            ),
          if (kSupportCamera)
            _buildTile(
              context,
              icon: SpIcons.videoCamera,
              label: tr('button.record_video'),
              action: .recordVideo,
            ),
          if (showRecordVoiceNote)
            _buildTile(
              context,
              icon: SpIcons.voice,
              label: tr('button.record_voice_note'),
              action: .recordVoiceNote,
            ),
          SizedBox(height: bottomPadding + 24.0),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required SpAddMediaAction action,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.maybeOf(context)?.pop(action),
    );
  }
}
