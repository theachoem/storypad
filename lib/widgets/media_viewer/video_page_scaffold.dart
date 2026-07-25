part of 'sp_media_viewer.dart';

const Duration _kSeekStep = Duration(seconds: 5);
const Duration _kAutoHideDelay = Duration(seconds: 3);
const List<double> _kSpeeds = [0.5, 1.0, 1.5, 2.0];

/// A single video page: its own [Scaffold] owning playback end-to-end -- the
/// [VideoPlayerController], a zoomable [PhotoView] body wrapping the player,
/// an app bar, and transport controls in the bottom bar.
///
/// The body is a [PhotoView] like [_ImagePageScaffold]'s, so tap-to-toggle,
/// pinch-zoom, pan and double-tap-to-zoom all behave identically whichever
/// kind of page the user swipes onto. Seeking and play/pause are buttons in
/// [_VideoCenterControls] rather than gestures, precisely so they don't
/// compete with zoom for the same taps. Controls auto-hide 3s after they're
/// last shown while the video is playing.
class _VideoPageScaffold extends StatefulWidget {
  const _VideoPageScaffold({
    required this.item,
    required this.index,
    required this.total,
    required this.controller,
  });

  final SpMediaViewerItem item;
  final int index;
  final int total;
  // Only used to detect "am I the current page" so a video swiped away from
  // pauses itself rather than keeping playing (and making noise) off-screen
  // -- no shared playback/visibility state is read or written here.
  final PageController controller;

  @override
  State<_VideoPageScaffold> createState() => _VideoPageScaffoldState();
}

class _VideoPageScaffoldState extends State<_VideoPageScaffold> {
  VideoPlayerController? controller;
  File? _file;
  bool controlsVisible = true;
  Timer? _autoHideTimer;
  // Incremented on every _createController call; lets a call detect it's
  // been superseded by a newer one (see _createController's doc comment).
  int _controllerGeneration = 0;

  // Set once the current controller's video reaches end-of-stream. The
  // Media3-based video_player_android backend never resumes producing frames
  // on that same controller after EOS -- position/isPlaying report normally,
  // but decoding is permanently stuck -- so once this is true, play/seek
  // requests recreate the controller instead of reusing it.
  bool _hasReachedEnd = false;

  late final DevicePreferencesProvider _preferencesProvider;
  late double _playbackSpeed;
  late bool _muted;

  // Previous value of [_isCurrentPage], so [_handlePageChange] can act on the
  // moment this page becomes (or stops being) the visible one.
  late bool _wasCurrentPage = _isCurrentPage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handlePageChange);

    // Persist the chosen speed like SpVoicePlayer does with voicePlaybackSpeed
    // -- otherwise every video reopens at 1.0x regardless of what the user
    // last picked. Mute is persisted the same way, so a user who watches
    // muted (e.g. in public) stays muted across videos and sessions.
    _preferencesProvider = context.read<DevicePreferencesProvider>();
    _playbackSpeed = _preferencesProvider.preferences.videoPlaybackSpeed;
    _muted = _preferencesProvider.preferences.videoMuted;
    _preferencesProvider.addListenerForVideoPlaybackSpeed(_onSpeedPreferenceChanged);
    _preferencesProvider.addListenerForVideoMuted(_onMutedPreferenceChanged);
    DeviceVolumeService.instance.addOnIncreaseListener(_handleVolumeIncreased);
  }

  void _onSpeedPreferenceChanged() {
    if (!mounted) return;
    if (_playbackSpeed == _preferencesProvider.preferences.videoPlaybackSpeed) return;

    _playbackSpeed = _preferencesProvider.preferences.videoPlaybackSpeed;
    controller?.setPlaybackSpeed(_playbackSpeed);
    setState(() {});
  }

  void _onMutedPreferenceChanged() {
    if (!mounted) return;
    if (_muted == _preferencesProvider.preferences.videoMuted) return;

    _muted = _preferencesProvider.preferences.videoMuted;
    controller?.setVolume(_muted ? 0.0 : 1.0);
    setState(() {});
  }

  void _cycleSpeed() {
    final currentIndex = _kSpeeds.indexOf(_playbackSpeed);
    final nextSpeed = _kSpeeds[(currentIndex + 1) % _kSpeeds.length];

    setState(() => _playbackSpeed = nextSpeed);
    controller?.setPlaybackSpeed(nextSpeed);

    // Update the provider last to avoid a redundant trigger from
    // _onSpeedPreferenceChanged: _playbackSpeed is already updated above, so
    // it detects no further change and skips itself.
    _preferencesProvider.setVideoPlaybackSpeed(nextSpeed);
  }

  void _toggleMute() => _setMuted(!_muted);

  void _setMuted(bool muted) {
    setState(() => _muted = muted);
    controller?.setVolume(muted ? 0.0 : 1.0);

    // Provider last, for the same reason as _cycleSpeed.
    _preferencesProvider.setVideoMuted(muted);
  }

  /// Turning the device volume up is a request for sound, so it unmutes --
  /// YouTube behaves the same way. Without this the video would stay silent no
  /// matter how far the user pushes the volume, with nothing on screen
  /// explaining why, and the persisted mute would keep every later video
  /// silent too. Controls are revealed so the icon flipping is actually seen.
  ///
  /// Only the visible page reacts: the [PageView] keeps neighbouring pages
  /// alive, and they'd each redundantly rewrite the same preference.
  void _handleVolumeIncreased() {
    if (!mounted || !_muted || !_isCurrentPage) return;

    _setMuted(false);
    _revealControls();
  }

  // hasClients guards the very first frame: PageController.page asserts if no
  // PageView is attached yet, and _createController can resolve that early.
  bool get _isCurrentPage {
    final page = widget.controller.hasClients ? widget.controller.page?.round() : null;
    return (page ?? widget.controller.initialPage) == widget.index;
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    widget.controller.removeListener(_handlePageChange);
    DeviceVolumeService.instance.removeOnIncreaseListener(_handleVolumeIncreased);
    _preferencesProvider.removeListenerForVideoPlaybackSpeed(_onSpeedPreferenceChanged);
    _preferencesProvider.removeListenerForVideoMuted(_onMutedPreferenceChanged);
    controller?.removeListener(_handleControllerValueChanged);
    controller?.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => controlsVisible = !controlsVisible);
    if (controlsVisible) {
      _scheduleAutoHide();
    } else {
      _autoHideTimer?.cancel();
    }
  }

  /// Shows the controls (if hidden) and (re)starts the 3s auto-hide clock --
  /// used after any explicit user interaction (seek, double-tap, resuming
  /// play) so the controls don't vanish mid-interaction.
  void _revealControls() {
    setState(() => controlsVisible = true);
    _scheduleAutoHide();
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_kAutoHideDelay, () {
      if (!mounted || controller?.value.isPlaying != true) return;
      setState(() => controlsVisible = false);
    });
  }

  /// Starts playback when this page is swiped onto and pauses it when it's
  /// swiped away, so a video is always playing iff it's the one on screen.
  ///
  /// Acts on the *transition* rather than on every notification: this fires
  /// continuously while a finger drags, and re-issuing play() each time would
  /// also fight the user pausing the video by hand (any later scroll jitter,
  /// e.g. an overscroll bounce, would restart it under them).
  void _handlePageChange() {
    if (_isCurrentPage == _wasCurrentPage) return;
    _wasCurrentPage = _isCurrentPage;

    if (_wasCurrentPage) {
      _autoPlay();
    } else {
      controller?.pause();
    }
  }

  /// Plays without the side effects of a deliberate [_handlePlayPause]: a
  /// video that already ran to the end stays parked on its last frame rather
  /// than silently restarting the moment the user swipes back to it.
  void _autoPlay() {
    final current = controller;
    if (current == null || !current.value.isInitialized) return;
    if (current.value.isPlaying || _hasReachedEnd) return;

    current.play();
    _scheduleAutoHide();
  }

  Future<void> _initController(File file) async {
    if (controller != null) return;
    _file = file;
    await _createController(file, autoplay: true);
  }

  /// Creates and initializes a fresh [VideoPlayerController] for [file],
  /// swaps it in, and disposes the previous one. Used both for the initial
  /// load and to work around the stuck-after-EOS bug described on
  /// [_hasReachedEnd].
  ///
  /// Guarded by [_controllerGeneration] against two failure modes: (1) the
  /// page being disposed (PageView swipe) while this is still awaiting
  /// initialize()/seekTo() -- without the check, the later setState() would
  /// fire on an unmounted State and newController would leak, never disposed;
  /// (2) two overlapping calls (e.g. a rapid double-tap-seek followed by a
  /// tap-play right at the end) racing to swap `controller` -- without the
  /// check, the loser's newController is never disposed either, since each
  /// call only disposes the oldController *it* captured.
  Future<void> _createController(File file, {required bool autoplay, Duration seekTo = Duration.zero}) async {
    final int generation = ++_controllerGeneration;

    final newController = VideoPlayerController.file(file);
    await newController.initialize();
    if (seekTo > Duration.zero) await newController.seekTo(seekTo);

    if (!mounted || generation != _controllerGeneration) {
      newController.dispose();
      return;
    }

    newController.addListener(_handleControllerValueChanged);
    // A fresh VideoPlayerController always starts at 1.0x and full volume --
    // without these, recreating the controller (the EOS workaround above)
    // would silently reset the user's chosen speed and unmute the video...
    await newController.setPlaybackSpeed(_playbackSpeed);
    await newController.setVolume(_muted ? 0.0 : 1.0);

    final oldController = controller;
    setState(() {
      controller = newController;
      _hasReachedEnd = false;
    });

    // ...but only if this page is the one on screen. The PageView builds
    // neighbouring pages ahead of time, so without this check a video one
    // swipe away starts playing (audibly) the moment it finishes loading.
    if (autoplay && _isCurrentPage) {
      await newController.play();
      _scheduleAutoHide();
    }

    oldController?.removeListener(_handleControllerValueChanged);
    await oldController?.dispose();
  }

  void _handleControllerValueChanged() {
    final isCompleted = controller?.value.isCompleted == true;

    if (isCompleted && !_hasReachedEnd) {
      _hasReachedEnd = true;
      // Video played through to the end while controls were hidden -- reveal
      // them so the user isn't left staring at a frozen frame with no
      // visible way to replay.
      _revealControls();
      return;
    }

    setState(() {});
  }

  Future<void> _handlePlayPause() async {
    final current = controller;
    if (current == null) return;

    if (current.value.isPlaying) {
      await current.pause();
      _autoHideTimer?.cancel();
      return;
    }

    if (_hasReachedEnd) {
      final file = _file;
      if (file != null) await _createController(file, autoplay: true);
      return;
    }

    await current.play();
    _revealControls();
  }

  Duration _clamp(Duration position, Duration duration) {
    if (position < Duration.zero) return Duration.zero;
    if (position > duration) return duration;
    return position;
  }

  /// Seeks to [target], handling the two special cases both [_seekBy] and
  /// [_handleSeekEnd] need:
  /// - if [target] reaches the end, pause there instead of resuming playback
  ///   -- video_player's play() auto-rewinds to zero when called at
  ///   position == duration, which would look like an unwanted restart.
  /// - if the controller is stuck-after-EOS ([_hasReachedEnd]), recreate it
  ///   instead of reusing it, since the native player never resumes
  ///   decoding on that instance again (seeking alone still works fine on
  ///   it though, so this isn't needed for the at-end case above).
  ///
  /// Playback resumes after the seek only if it was already playing --
  /// seeking while paused (e.g. to inspect a specific frame) stays paused,
  /// it doesn't implicitly resume.
  Future<void> _seekAndMaybeResume(Duration target) async {
    final current = controller;
    if (current == null) return;

    final wasPlaying = current.value.isPlaying;

    if (target >= current.value.duration) {
      await current.pause();
      await current.seekTo(target);
    } else if (_hasReachedEnd) {
      final file = _file;
      if (file != null) await _createController(file, autoplay: wasPlaying, seekTo: target);
    } else {
      await current.seekTo(target);
      if (wasPlaying) await current.play();
    }

    _revealControls();
  }

  Future<void> _seekBy(Duration delta) async {
    final current = controller;
    if (current == null) return;

    final target = _clamp(current.value.position + delta, current.value.duration);
    await _seekAndMaybeResume(target);
  }

  // Seeking itself still works fine on a stuck-after-EOS controller (only
  // resuming playback doesn't) -- so the live scrub preview isn't gated on
  // [_hasReachedEnd]. The auto-hide timer is paused for the duration of the
  // drag so the control bar (including the slider being dragged) can't fade
  // out mid-gesture; [_seekAndMaybeResume] reschedules it once the drag ends.
  void _handleSeekChanged(Duration position) {
    _autoHideTimer?.cancel();
    controller?.seekTo(position);
  }

  Future<void> _handleSeekEnd(Duration position) => _seekAndMaybeResume(position);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _Chrome(
          visible: controlsVisible,
          child: _buildAppBar(context, index: widget.index, total: widget.total, item: widget.item),
        ),
      ),
      bottomNavigationBar: _Chrome(
        visible: controlsVisible,
        child: _VideoControls(
          controller: controller,
          playbackSpeed: _playbackSpeed,
          muted: _muted,
          onSeekChanged: _handleSeekChanged,
          onSeekEnd: _handleSeekEnd,
          onCycleSpeed: _cycleSpeed,
          onToggleMute: _toggleMute,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SpDbAssetLoader.withUser(
      relativePath: widget.item.tag,
      builder: (context, file, error) {
        if (file != null) _initController(file);

        if (error != null) {
          return const Center(
            child: Icon(SpIcons.imageNotSupported, color: Colors.white, size: 40.0),
          );
        }

        final playerController = controller;
        if (playerController == null || !playerController.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: PhotoView.customChild(
                // Native pixel size, so "contained" fits the video the same way
                // it fits an image -- zoom limits and panning bounds then
                // follow the video itself, not the letterboxed viewport.
                childSize: playerController.value.size,
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.contained * 4.0,
                backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                onTapUp: (context, details, value) => _toggleControls(),
                child: VideoPlayer(playerController),
              ),
            ),
            // Sits above the player but only occupies the row of buttons
            // itself, so taps anywhere around it still reach PhotoView -- and
            // _Chrome makes it ignore pointers entirely once hidden.
            Positioned.fill(
              child: _Chrome(
                visible: controlsVisible,
                child: Center(
                  child: _VideoCenterControls(
                    isPlaying: playerController.value.isPlaying,
                    onSeekBackward: () => _seekBy(-_kSeekStep),
                    onSeekForward: () => _seekBy(_kSeekStep),
                    onPlayPause: _handlePlayPause,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({
    required this.controller,
    required this.playbackSpeed,
    required this.muted,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onCycleSpeed,
    required this.onToggleMute,
  });

  final VideoPlayerController? controller;
  final double playbackSpeed;
  // Owned by the parent (persisted in device preferences) rather than read off
  // VideoPlayerValue.volume, so the icon still shows the user's intent while a
  // controller is being recreated and hasn't had its volume re-applied yet.
  final bool muted;
  final ValueChanged<Duration> onSeekChanged;
  final ValueChanged<Duration> onSeekEnd;
  final VoidCallback onCycleSpeed;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) return const SizedBox.shrink();

    return _buildContainer(context, controller.value);
  }

  Widget _buildContainer(BuildContext context, VideoPlayerValue value) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black54,
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // Left inset matches the scrubber's own padding below, so the
            // timestamp lines up with the start of the track. The right side
            // stays tight because the icon button brings its own padding.
            padding: const EdgeInsets.only(left: 20.0, right: 4.0),
            child: Row(
              children: [
                Text(
                  '${DurationFormatService.formatDuration(value.position)} / ${DurationFormatService.formatDuration(value.duration)}',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onCycleSpeed,
                  child: Text(
                    '${playbackSpeed}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  color: Colors.white,
                  icon: SpAnimatedIcons.fadeScale(
                    showFirst: muted,
                    firstChild: const Icon(SpIcons.volumeOff),
                    secondChild: const Icon(SpIcons.volumeUp),
                  ),
                  onPressed: onToggleMute,
                ),
              ],
            ),
          ),
          _buildScrubber(context, value),
        ],
      ),
    );
  }

  Widget _buildScrubber(BuildContext context, VideoPlayerValue value) {
    final durationMs = value.duration.inMilliseconds.toDouble();
    final positionMs = value.position.inMilliseconds.toDouble().clamp(0.0, durationMs <= 0 ? 0.0 : durationMs);

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
      ),
      child: Slider(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        value: positionMs,
        max: durationMs > 0 ? durationMs : 1.0,
        activeColor: Colors.white,
        inactiveColor: Colors.white24,
        onChanged: (newValue) => onSeekChanged(Duration(milliseconds: newValue.toInt())),
        onChangeEnd: (newValue) => onSeekEnd(Duration(milliseconds: newValue.toInt())),
      ),
    );
  }
}

/// Seek -5s / play-pause / seek +5s, floated over the middle of the video.
///
/// These are buttons rather than the tap gestures a video player usually has
/// (double-tap halves to seek, tap to play/pause) because the page shares its
/// gestures with [PhotoView]: taps toggle the chrome and double taps zoom,
/// exactly as on an image page, so there's nothing left to seek with.
class _VideoCenterControls extends StatelessWidget {
  const _VideoCenterControls({
    required this.isPlaying,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.onPlayPause,
  });

  final bool isPlaying;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;
  final VoidCallback onPlayPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 16.0,
      children: [
        _buildButton(icon: const Icon(SpIcons.replay5), size: 32.0, onPressed: onSeekBackward),
        _buildButton(
          icon: SpAnimatedIcons.fadeScale(
            showFirst: isPlaying,
            firstChild: const Icon(SpIcons.pauseCircle),
            secondChild: const Icon(SpIcons.playCircle),
          ),
          size: 56.0,
          onPressed: onPlayPause,
        ),
        _buildButton(icon: const Icon(SpIcons.forward5), size: 32.0, onPressed: onSeekForward),
      ],
    );
  }

  Widget _buildButton({required Widget icon, required double size, required VoidCallback onPressed}) {
    return IconButton(
      color: Colors.white,
      iconSize: size,
      onPressed: onPressed,
      // The video behind can be any colour, and unlike the top/bottom bars
      // there's no gradient scrim out here to sit the icons against.
      icon: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 16.0)],
        ),
        child: icon,
      ),
    );
  }
}
