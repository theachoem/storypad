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
/// - Supports lazy-loading audio files via callback
///
/// Usage:
/// ```dart
/// // Direct file path (no download needed)
/// SpAudioPlayer(filePath: '/path/to/audio.m4a')
///
/// // With lazy-loading callback (download on play)
/// SpAudioPlayer(
///   onDownloadRequested: () async {
///     // Download logic here
///     return downloadedFilePath;
///   },
/// )
/// ```
class SpAudioPlayer extends StatefulWidget {
  const SpAudioPlayer({
    super.key,
    this.filePath,
    this.onDownloadRequested,
    required this.initialDuration,
  }) : assert(
         filePath != null || onDownloadRequested != null,
         'Either filePath or onDownloadRequested must be provided',
       );

  /// Direct path to audio file. Use when file is already available locally.
  final String? filePath;
  final Duration? initialDuration;

  /// Callback to get/download audio file on play. Called when user clicks play.
  /// Should return the path to the audio file.
  final Future<String> Function()? onDownloadRequested;

  @override
  State<SpAudioPlayer> createState() => _SpAudioPlayerState();
}

class _SpAudioPlayerState extends State<SpAudioPlayer> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool playing = false;
  bool downloading = false;

  late Duration _duration = widget.initialDuration ?? Duration.zero;
  Duration _position = Duration.zero;
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();

    // If filePath is provided directly, load it immediately
    if (widget.filePath != null) {
      _currentFilePath = widget.filePath;
      _loadAudio(_currentFilePath!);
    }
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
          _duration = duration ?? _duration;
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

  Future<void> _loadAudio(String filePath) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.setFilePath(filePath);
    } catch (e) {
      debugPrint('❌ Error loading audio: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await _audioPlayer.setFilePath(filePath);
      } catch (retryError) {
        debugPrint('❌ Error loading audio (retry): $retryError');
      }
    }
  }

  Future<void> _ensureAudioLoaded() async {
    // If file is already loaded or loading, skip
    if (_currentFilePath != null) return;

    // If no onDownloadRequested callback, file must be provided directly
    if (widget.onDownloadRequested == null) {
      debugPrint('❌ No file path or download callback provided');
      return;
    }

    try {
      if (mounted) setState(() => downloading = true);
      final filePath = await widget.onDownloadRequested!();

      if (mounted) {
        setState(() {
          _currentFilePath = filePath;
          downloading = false;
        });
      }

      await _loadAudio(filePath);
    } catch (e) {
      debugPrint('❌ Error preparing audio: $e');
      if (mounted) setState(() => downloading = false);
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      // Ensure audio is loaded first (handles lazy loading)
      await _ensureAudioLoaded();

      if (downloading) {
        return; // Don't toggle while loading
      }

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
          onTap: downloading ? null : () => _togglePlayPause(),
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
                      child: downloading
                          ? SizedBox(
                              width: 18.0,
                              height: 18.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
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
