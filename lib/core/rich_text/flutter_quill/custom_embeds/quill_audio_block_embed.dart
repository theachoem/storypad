part of '../quill_adapter.dart';

class _QuillAudioBlockEmbed extends quill.EmbedBuilder {
  _QuillAudioBlockEmbed();

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

  @override
  void initState() {
    super.initState();

    loadAssetMetadata();
  }

  /// Load asset metadata (but not the file itself)
  Future<void> loadAssetMetadata() async {
    try {
      final relativePath = widget.node.value.data;
      final asset = await AssetDbModel.findBy(relativePath: relativePath);

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

    final currentUser = context.read<BackupProvider>().currentUser;
    final downloader = GoogleDriveAssetDownloaderService();

    return downloader.downloadAsset(
      asset: _asset!,
      currentUser: currentUser,
      localFile: _asset!.localFile,
    );
  }

  void remove() {
    if (widget.readOnly) return;

    widget.controller.replaceText(
      widget.node.documentOffset,
      widget.node.length,
      '',
      widget.controller.selection,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_asset == null) return const SizedBox.shrink();

    return SpVoicePlayer.network(
      initialDuration: _asset?.durationInMs != null ? Duration(milliseconds: _asset!.durationInMs!) : null,
      onDownloadRequested: _downloadAudio,
      onLongPress: () {
        SpAssetInfoSheet(
          asset: _asset!,
          onRemoveAssetEmbed: widget.readOnly ? null : () => remove(),
        ).show(context: context);
      },
    );
  }
}
