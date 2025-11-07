import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/services/duration_format_service.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

/// A reusable audio player widget with a clean, minimal design.
///
/// Features:
/// - Play/pause button with progress bar
/// - Duration display (current / total)
/// - Clean stadium-shaped design
/// - Responds to app lifecycle changes
/// - Manages AudioPlayer internally
///
/// Usage:
/// ```dart
/// SpAudioPlayer(filePath: '/path/to/audio.m4a')
/// ```
class SpAudioPlayer extends StatefulWidget {
  const SpAudioPlayer({
    super.key,
    required this.filePath,
  });

  final String filePath;

  @override
  State<SpAudioPlayer> createState() => _SpAudioPlayerState();
}

class _SpAudioPlayerState extends State<SpAudioPlayer> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool playing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();
    _loadAudio();
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
          playing = state.playing;
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

  Future<void> _loadAudio() async {
    try {
      // Give the system a moment to finalize the file
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.setFilePath(widget.filePath);
    } catch (e) {
      debugPrint('❌ Error loading audio: $e');
      // Retry once
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await _audioPlayer.setFilePath(widget.filePath);
      } catch (retryError) {
        debugPrint('❌ Error loading audio (retry): $retryError');
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (playing) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SpTapEffect(
          effects: [SpTapEffectType.scaleDown],
          onTap: () => _togglePlayPause(),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            clipBehavior: Clip.hardEdge,
            shape: StadiumBorder(
              side: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  bottom: 0,
                  top: 0,
                  child: Container(
                    width:
                        (_duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0) *
                        constraints.maxWidth,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        playing ? SpIcons.pauseCircle : SpIcons.playCircle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18.0,
                      ),
                    ),
                    Text(
                      DurationFormatService.formatDuration(_position),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DurationFormatService.formatDuration(_duration),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
