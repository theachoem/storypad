import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/duration_format_service.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

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

class _QuillAudioRendererState extends State<_QuillAudioRenderer> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  AssetDbModel? _asset;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addObserver(this);

    _loadAsset();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause playback when app goes to background
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });

        // When playback completes, stop and revert to initial state
        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.pause();
          _audioPlayer.seek(Duration.zero);
        }
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  Future<void> _loadAsset() async {
    try {
      final link = widget.node.value.data;
      final asset = await AssetDbModel.findBy(assetLink: link);

      if (mounted && asset != null) {
        setState(() {
          _asset = asset;
        });

        // Pre-load the audio
        final file = asset.localFile;
        if (file != null && file.existsSync()) {
          await _audioPlayer.setFilePath(file.path);
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading audio file: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('❌ Error toggling playback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return buildLoading(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildAudioPlayerControls(context),
          const SizedBox(height: 12.0),
          buildProgressBar(context),
        ],
      ),
    );
  }

  Widget buildProgressBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: LinearProgressIndicator(
        value: _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0,
        minHeight: 4.0,
        backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        valueColor: AlwaysStoppedAnimation(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget buildAudioPlayerControls(BuildContext context) {
    return Row(
      children: [
        SpTapEffect(
          onTap: () => _togglePlayPause(),
          child: Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _isPlaying ? SpIcons.pauseCircle : SpIcons.playCircle,
                color: Theme.of(context).colorScheme.primary,
                size: 24.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Recording',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Text(
                    DurationFormatService.formatDuration(_position),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _asset?.formattedDuration ?? DurationFormatService.formatDuration(_duration),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Container buildLoading(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
