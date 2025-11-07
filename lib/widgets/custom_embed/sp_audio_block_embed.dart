import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/google_drive_asset_downloader_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/sp_audio_player.dart';

class SpAudioBlockEmbed extends quill.EmbedBuilder {
  SpAudioBlockEmbed();

  @override
  String get key => "audio";

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    return _QuillAudioRenderer(
      controller: embedContext.controller,
      readOnly: embedContext.readOnly,
      node: embedContext.node,
    );
  }
}

class _QuillAudioRenderer extends StatefulWidget {
  const _QuillAudioRenderer({
    required this.node,
    required this.controller,
    required this.readOnly,
  });

  final quill.Embed node;
  final quill.QuillController controller;
  final bool readOnly;

  @override
  State<_QuillAudioRenderer> createState() => _QuillAudioRendererState();
}

class _QuillAudioRendererState extends State<_QuillAudioRenderer> {
  AssetDbModel? _asset;
  late BuildContext _builderContext;

  @override
  void initState() {
    super.initState();

    loadAssetMetadata();
  }

  /// Load asset metadata (but not the file itself)
  Future<void> loadAssetMetadata() async {
    try {
      final embedLink = widget.node.value.data;
      final asset = await AssetDbModel.findBy(embedLink: embedLink);

      if (mounted && asset != null) {
        setState(() {
          _asset = asset;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading audio metadata: $e');
    }
  }

  Future<String> _downloadAudio() async {
    if (_asset == null) {
      throw StateError('Asset metadata not loaded');
    }

    final currentUser = _builderContext.read<BackupProvider>().currentUser;
    final downloader = GoogleDriveAssetDownloaderService();

    return downloader.downloadAsset(
      asset: _asset!,
      currentUser: currentUser,
      localFile: _asset!.localFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_asset == null) return const SizedBox.shrink();
    _builderContext = context;

    return SpAudioPlayer(
      onDownloadRequested: _downloadAudio,
    );
  }
}
