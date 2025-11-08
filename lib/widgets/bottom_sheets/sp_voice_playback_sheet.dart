import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_voice_player.dart';

/// Sheet for playing voice notes
///
/// Usage:
/// ```dart
/// await SpVoicePlaybackSheet(asset: voiceAsset).show(context);
/// ```
class SpVoicePlaybackSheet extends BaseBottomSheet {
  const SpVoicePlaybackSheet({
    required this.asset,
  });

  final AssetDbModel asset;

  @override
  bool get fullScreen => false;

  @override
  bool get showMaterialDragHandle => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return _VoicePlaybackContent(
      asset: asset,
      bottomPadding: bottomPadding,
    );
  }
}

class _VoicePlaybackContent extends StatelessWidget {
  const _VoicePlaybackContent({
    required this.asset,
    required this.bottomPadding,
  });

  final AssetDbModel asset;
  final double bottomPadding;

  Future<String> _downloadAudio(BuildContext context) async {
    final currentUser = context.read<BackupProvider>().currentUser;
    final downloader = GoogleDriveAssetDownloaderService();

    return downloader.downloadAsset(
      asset: asset,
      currentUser: currentUser,
      localFile: asset.localFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: bottomPadding + 16.0,
      ),
      child: SpVoicePlayer.network(
        autoplay: true,
        onDownloadRequested: () => _downloadAudio(context),
        initialDuration: asset.durationInMs != null ? Duration(milliseconds: asset.durationInMs!) : null,
      ),
    );
  }
}
