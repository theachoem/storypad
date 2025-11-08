import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/duration_format_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

/// A reusable audio player widget with a clean, minimal design inspired by Telegram's audio player UX.
///
/// This widget provides a polished audio playback experience with intuitive gesture controls
/// similar to Telegram's audio message player, making it familiar and easy to use.
///
/// Provides two convenient factory constructors for different use cases:
/// - [SpVoicePlayer.file] - For playing local audio files
/// - [SpVoicePlayer.network] - For lazy-loading/downloading audio on demand
///
/// **Core Features:**
/// - Play/pause button with visual feedback (shows current state)
/// - Duration display (current / total time in MM:SS format)
/// - Clean stadium-shaped design with progress bar
/// - Responds to app lifecycle changes (pauses on background)
/// - Manages AudioPlayer internally with proper disposal
/// - Supports lazy-loading audio files via callback
/// - Long-press to reset playback to beginning
/// - Playback speed cycling (1x → 1.5x → 2x → loops)
/// - Horizontal drag to scrub through audio
///
/// **Telegram-Inspired Interactions:**
/// - **Tap**: Play/pause toggle (center of widget)
/// - **Long Press**: Reset to beginning (seek to 0:00)
/// - **Horizontal Drag**: Scrub through audio (pauses + seeks on release)
/// - **Tap Speed Indicator**: Cycle through speeds (1x → 1.5x → 2x → 1x)
/// - **Drag Constraints**: Only available after playback has started (position > 0)
///
/// **Design Philosophy:**
/// - Minimal, uncluttered UI focused on essential controls
/// - Smooth animations and haptic feedback
/// - Intuitive gesture vocabulary users know from Telegram
/// - Real-time visual feedback during interactions
/// - Responsive to all app states (background/foreground)
class SpVoicePlayer extends StatefulWidget {
  const SpVoicePlayer._({
    super.key,
    this.filePath,
    this.onDownloadRequested,
    required this.initialDuration,
    this.onLongPress,
    this.autoplay = false,
  }) : assert(
         filePath != null || onDownloadRequested != null,
         'Either filePath or onDownloadRequested must be provided',
       );

  /// Direct path to audio file. Use when file is already available locally.
  final String? filePath;

  /// Initial duration hint for pre-sizing (e.g., from database metadata).
  /// Updated when audio actually loads.
  final Duration? initialDuration;

  /// Whether to start playback immediately when widget is mounted.
  final bool autoplay;

  /// Callback to get/download audio file on play. Called when user clicks play.
  /// Useful for lazy-loading from cloud storage or downloading on-demand.
  /// Should return the path to the audio file.
  final Future<String> Function()? onDownloadRequested;

  final void Function()? onLongPress;

  /// Factory constructor for local file playback
  factory SpVoicePlayer.file({
    Key? key,
    required String filePath,
    Duration? initialDuration,
    bool autoplay = false,
    void Function()? onLongPress,
  }) {
    return SpVoicePlayer._(
      key: key,
      filePath: filePath,
      initialDuration: initialDuration,
      autoplay: autoplay,
      onLongPress: onLongPress,
    );
  }

  /// Factory constructor for network/lazy-loaded audio
  /// Usage: SpVoicePlayer.network(
  ///   onDownloadRequested: () => googleDriveDownloadAudio(assetId),
  /// )
  factory SpVoicePlayer.network({
    Key? key,
    required Future<String> Function() onDownloadRequested,
    Duration? initialDuration,
    bool autoplay = false,
    void Function()? onLongPress,
  }) {
    return SpVoicePlayer._(
      key: key,
      onDownloadRequested: onDownloadRequested,
      initialDuration: initialDuration,
      autoplay: autoplay,
      onLongPress: onLongPress,
    );
  }

  @override
  State<SpVoicePlayer> createState() => _SpVoicePlayerState();
}

class _SpVoicePlayerState extends State<SpVoicePlayer> with WidgetsBindingObserver {
  /// AudioPlayer instance managed by this widget.
  /// Handles actual playback using the just_audio package.
  final AudioPlayer player = AudioPlayer();

  /// Whether audio is currently playing.
  bool playing = false;

  /// Whether we're in the process of downloading/loading audio.
  bool downloading = false;

  /// Total duration of the audio file.
  /// Updated when audio loads, or uses initialDuration as hint.
  late Duration _duration = widget.initialDuration ?? Duration.zero;

  /// Current playback position in the audio file.
  /// Updated continuously during playback.
  Duration _position = Duration.zero;

  /// Path to currently loaded audio file (local or downloaded).
  /// Once set, this asset stays loaded until widget is disposed.
  String? _currentFilePath;

  /// Current playback speed (1.0 = normal, 1.5 = 50% faster, 2.0 = 2x faster).
  /// Synced with JustAudio's internal speed setting and device preferences.
  late double _playbackSpeed;

  /// Available speed options for cycling behavior.
  /// Users tap the speed indicator to cycle: 1.0 → 1.5 → 2.0 → 1.0
  final List<double> _speedOptions = [1.0, 1.5, 2.0];

  /// Whether user is currently dragging to scrub audio.
  /// While dragging, audio is paused and time updates from drag input.
  bool _isDragging = false;

  /// Temporary position during drag operation.
  /// Applied when user releases drag (seeks to this position).
  late Duration _draggedPosition;

  late final DevicePreferencesProvider _preferencesProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();

    // setup to read voicePlaybackSpeed from provider
    _preferencesProvider = context.read<DevicePreferencesProvider>();
    _playbackSpeed = _preferencesProvider.preferences.voicePlaybackSpeed;
    _preferencesProvider.addListenerForVoicePlaybackSpeed(_onPreferencesChanged);

    if (widget.filePath != null) {
      _currentFilePath = widget.filePath;
      _loadAudio(_currentFilePath!);
    }

    if (widget.autoplay) togglePlayPause();
  }

  void _onPreferencesChanged() async {
    if (!mounted) return;
    if (_playbackSpeed == _preferencesProvider.preferences.voicePlaybackSpeed) return;

    debugPrint('$runtimeType#_onPreferencesChanged setting _playbackSpeed');

    _playbackSpeed = _preferencesProvider.preferences.voicePlaybackSpeed;
    await player.setSpeed(_playbackSpeed);

    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _preferencesProvider.removeListenerForVoicePlaybackSpeed(_onPreferencesChanged);
    player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause playback when app goes to background
    if (state == AppLifecycleState.paused) player.pause();
  }

  /// Sets up listeners for AudioPlayer state changes.
  void _setupAudioPlayer() {
    player.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() => playing = state.playing);

      // When audio reaches the end, pause and reset to beginning
      if (state.processingState == ProcessingState.completed) {
        player.pause();
        player.seek(Duration.zero);
      }
    });

    player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration ?? _duration);
    });

    player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
  }

  Future<void> _loadAudio(String filePath) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await player.setFilePath(filePath);
    } catch (e) {
      debugPrint('❌ Error loading audio: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        await player.setFilePath(filePath);
      } catch (retryError) {
        debugPrint('❌ Error loading audio (retry): $retryError');
      }
    }
  }

  /// Ensures audio file is loaded before playback.
  /// Handles lazy-loading where audio is downloaded on-demand.
  Future<void> _ensureAudioLoaded() async {
    if (_currentFilePath != null) return;

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

  /// Toggle between play and pause states.
  /// Inspired by Telegram: single tap on center toggles playback.
  Future<void> togglePlayPause() async {
    Feedback.forTap(context);

    try {
      await _ensureAudioLoaded();
      if (downloading) return;
      if (player.speed != _playbackSpeed) await player.setSpeed(_playbackSpeed);
      if (playing) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      debugPrint('❌ Error toggling playback: $e');
    }
  }

  /// Cycle to next playback speed (1.0x → 1.5x → 2.0x → loops).
  /// Inspired by Telegram: tap the speed indicator to cycle through speeds.
  void cycleToNextSpeed() {
    if (mounted) Feedback.forTap(context);

    final currentIndex = _speedOptions.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % _speedOptions.length;
    final nextSpeed = _speedOptions[nextIndex];

    if (!mounted) return;

    setState(() => _playbackSpeed = nextSpeed);
    player.setSpeed(nextSpeed);

    // Update the provider last to avoid redundant triggers from the preference change listener.
    // This ensures _playbackSpeed is already updated, so the listener detects no further changes and skips itself.
    // See [initState]
    _preferencesProvider.setVoicePlaybackSpeed(nextSpeed);
  }

  /// Handle horizontal drag gestures to scrub through audio.
  /// Only allows drag when audio has started playing (position > 0).
  void handleHorizontalDrag(DragUpdateDetails details, double maxWidth) {
    if (_position == Duration.zero || _duration == Duration.zero) {
      return;
    }

    if (!_isDragging) {
      _isDragging = true;
      player.pause();
      _draggedPosition = _position;
    }

    final dragDelta = details.delta.dx;
    final percentageChange = dragDelta / maxWidth;
    final timeChange = Duration(milliseconds: (_duration.inMilliseconds * percentageChange).toInt());
    final newPosition = _draggedPosition + timeChange;

    Duration clampPosition(Duration position, Duration min, Duration max) {
      if (position < min) return min;
      if (position > max) return max;
      return position;
    }

    final clampedPosition = clampPosition(newPosition, Duration.zero, _duration);

    setState(() {
      _draggedPosition = clampedPosition;
    });
  }

  /// Handle end of horizontal drag gesture.
  /// Seeks audio player to the final dragged position.
  void handleHorizontalDragEnd() async {
    _isDragging = false;

    try {
      await player.seek(_draggedPosition);
    } catch (e) {
      debugPrint('❌ Error seeking to position: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: downloading ? null : () => togglePlayPause(),
          onLongPress: widget.onLongPress != null
              ? () {
                  Feedback.forLongPress(context);
                  widget.onLongPress!();
                }
              : null,
          onHorizontalDragUpdate: downloading ? null : (details) => handleHorizontalDrag(details, constraints.maxWidth),
          onHorizontalDragEnd: downloading ? null : (_) => handleHorizontalDragEnd(),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Stack(
              children: [
                buildCurrentPositionBackground(constraints, context),
                Row(
                  children: [
                    buildPlayPauseButton(context),
                    Text(
                      DurationFormatService.formatDuration(_isDragging ? _draggedPosition : _position),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    buildSpeedLabelButton(context),
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

  /// Build play/pause button or loading indicator.
  Widget buildPlayPauseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: downloading
          ? SizedBox(
              width: 18.0,
              height: 18.0,
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : SpAnimatedIcons.fadeScale(
              duration: Durations.medium4,
              showFirst: playing,
              firstChild: Icon(
                SpIcons.pauseCircle,
                color: Theme.of(context).colorScheme.primary,
                size: 18.0,
              ),
              secondChild: Icon(
                SpIcons.playCircle,
                color: Theme.of(context).colorScheme.primary,
                size: 18.0,
              ),
            ),
    );
  }

  /// Build speed indicator button that cycles speeds on tap (1.0x → 1.5x → 2.0x → 1.0x).
  Widget buildSpeedLabelButton(BuildContext context) {
    return Stack(
      children: _speedOptions.map((speed) {
        return Visibility(
          visible: _position > Duration.zero && speed == _playbackSpeed,
          child: SpFadeIn.fromRight(
            duration: Durations.long1,
            child: SpTapEffect(
              onTap: cycleToNextSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Text(
                  '${speed}x',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build progress bar background that fills from left to right.
  Widget buildCurrentPositionBackground(BoxConstraints constraints, BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      top: 0,
      child: Container(
        width:
            (_duration.inMilliseconds > 0
                ? (_isDragging ? _draggedPosition.inMilliseconds : _position.inMilliseconds) / _duration.inMilliseconds
                : 0) *
            constraints.maxWidth,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
