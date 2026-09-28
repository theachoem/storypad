import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/assets/backup_asset_downloader_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/bottom_sheets/sp_asset_info_sheet.dart';
import 'package:storypad/widgets/sp_voice_player.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// A voice note. The value is the relative audio path, e.g. `audio/1762500783747.m4a`.
///
/// - Quill: `{"audio": "audio/….m4a"}`.
/// - Markdown: `<audio controls src="audio/….m4a"></audio>`.
class AudioEmbed extends StoryEmbed<String> {
  const AudioEmbed();

  @override
  String get type => 'audio';

  @override
  Set<String> get quillKeys => const {'audio'};

  @override
  Set<String> get htmlTags => const {'audio'};

  @override
  String? fromQuill(QuillEmbedOp op) {
    final value = op.value;
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  QuillEmbedOp toQuill(String value) => QuillEmbedOp.of('audio', value);

  @override
  String? fromHtml(StoryHtmlElement element) {
    final src = element['src'];
    return src == null || src.isEmpty ? null : src;
  }

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('audio', attributes: {'controls': '', 'src': value});

  @override
  Widget build(BuildContext context, StoryEmbedContext<String> embed) => _AudioEmbedView(embed: embed);
}

class _AudioEmbedView extends StatefulWidget {
  const _AudioEmbedView({required this.embed});

  final StoryEmbedContext<String> embed;

  @override
  State<_AudioEmbedView> createState() => _AudioEmbedViewState();
}

class _AudioEmbedViewState extends State<_AudioEmbedView> {
  AssetDbModel? _asset;

  @override
  void initState() {
    super.initState();
    _loadAssetMetadata();
  }

  @override
  void didUpdateWidget(_AudioEmbedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embed.value != widget.embed.value) _loadAssetMetadata();
  }

  /// Loads the asset's metadata (not the file itself).
  Future<void> _loadAssetMetadata() async {
    try {
      final asset = await AssetDbModel.findBy(relativePath: widget.embed.value);
      if (mounted && asset != null) setState(() => _asset = asset);
    } catch (e) {
      AppLogger.error('$runtimeType#_loadAssetMetadata error loading audio metadata', tag: '$runtimeType', error: e);
    }
  }

  Future<String> _downloadAudio() async {
    final asset = _asset;
    if (asset == null) throw StateError('Asset metadata not loaded');

    final signedInServices = context.read<BackupProvider>().signedInServices;
    return BackupAssetDownloaderService().downloadAsset(asset: asset, signedInServices: signedInServices);
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    if (asset == null) return const SizedBox.shrink();

    return SpVoicePlayer.network(
      initialDuration: asset.durationInMs != null ? Duration(milliseconds: asset.durationInMs!) : null,
      onDownloadRequested: _downloadAudio,
      onLongPress: () {
        SpAssetInfoSheet(
          asset: asset,
          onRemoveAssetEmbed: widget.embed.readOnly ? null : widget.embed.remove,
        ).show(context: context);
      },
    );
  }
}
