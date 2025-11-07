import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:storypad/core/databases/models/asset_db_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      final link = widget.node.value.data;
      final asset = await AssetDbModel.findBy(assetLink: link);

      if (mounted && asset != null) {
        setState(() {
          _asset = asset;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading audio file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_asset == null) {
      return const SizedBox.shrink();
    }

    final file = _asset!.localFile;
    if (file == null || !file.existsSync()) {
      return const SizedBox.shrink();
    }

    return SpAudioPlayer(filePath: file.path);
  }
}
