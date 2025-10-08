import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';
import 'package:storypad/core/types/notification_channel.dart';

class MultiAudioNotificationService {
  final Future<void> Function() onPlayed;
  final Future<void> Function() onPaused;
  final Future<void> Function() onClosed;

  _PlatformPlaybackListener? _audioHandler;

  MultiAudioNotificationService({
    required this.onPlayed,
    required this.onPaused,
    required this.onClosed,
  });

  Completer<bool>? _completer;
  Future<bool> initialIfNeed() async {
    if (_completer != null) return _completer!.future;

    _completer = Completer();
    _audioHandler = await AudioService.init(
      builder: () => _PlatformPlaybackListener(this),
      config: AudioServiceConfig(
        androidNotificationIcon: 'drawable/ic_music_note',
        androidNotificationChannelId: NotificationChannel.relaxingSound.channelID,
        androidNotificationChannelName: NotificationChannel.relaxingSound.channelName,
        androidShowNotificationBadge: true,
        preloadArtwork: true,
      ),
    );

    _completer?.complete(true);
    return true;
  }

  Future<void> showPlaying({
    required bool ready,
    required String title,
    required String artist,
    required Duration? duration,
    required String? backgroundUrlPath,
  }) async {
    debugPrint('$runtimeType#showPlaying ready: $ready');
    await initialIfNeed();

    _audioHandler?.mediaItem.add(
      MediaItem(
        id: 'relax_music',
        title: title,
        artist: kAppName,
        artUri: _audioHandler?.mediaItem.valueOrNull?.artUri,
        // Only set duration on Android as it show without allowing seeking.
        duration: Platform.isAndroid ? duration : null,
      ),
    );

    if (backgroundUrlPath != null) {
      FirestoreStorageService.instance.downloadFile(backgroundUrlPath).then((result) {
        if (result.file == null) return;
        _audioHandler?.mediaItem.add(_audioHandler?.mediaItem.value?.copyWith(artUri: Uri.file(result.file!.path)));
      });
    }

    _audioHandler?.playbackState.add(
      PlaybackState(
        controls: [MediaControl(androidIcon: 'drawable/ic_stop', label: tr("button.stop"), action: MediaAction.stop)],
        systemActions: const {MediaAction.playPause},
        processingState: ready ? AudioProcessingState.ready : AudioProcessingState.buffering,
        repeatMode: AudioServiceRepeatMode.all,
        playing: true,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
  }

  Future<void> showPause({
    required bool ready,
    required String title,
    required String artist,
    required Duration? duration,
    required String? backgroundUrlPath,
  }) async {
    debugPrint('$runtimeType#showPause ready: $ready');
    await initialIfNeed();

    _audioHandler?.playbackState.add(
      PlaybackState(
        controls: [MediaControl(androidIcon: 'drawable/ic_stop', label: tr("button.stop"), action: MediaAction.stop)],
        systemActions: const {MediaAction.playPause},
        processingState: ready ? AudioProcessingState.ready : AudioProcessingState.buffering,
        repeatMode: AudioServiceRepeatMode.all,
        playing: false,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
  }

  Future<void> close() async {
    if (_audioHandler == null || _audioHandler!.playbackState.isClosed) return;
    _audioHandler?.playbackState.add(PlaybackState());
  }

  void notifyUser({
    required String title,
    required String artist,
    required Map<String, PlayerState> playingStates,
    required Duration? stopIn,
    required String? backgroundUrlPath,
  }) {
    bool? anyPlaying = playingStates.values.isEmpty ? null : playingStates.values.any((e) => e.playing);
    bool? anyReady = playingStates.values.isEmpty
        ? null
        : playingStates.values.any((e) => e.processingState == ProcessingState.ready);

    if (anyPlaying == true) {
      showPlaying(
        ready: anyReady == true,
        title: title,
        duration: stopIn,
        backgroundUrlPath: backgroundUrlPath,
        artist: artist,
      );
    } else if (anyPlaying == false) {
      showPause(
        ready: anyReady == true,
        title: title,
        duration: stopIn,
        backgroundUrlPath: backgroundUrlPath,
        artist: artist,
      );
    } else if (anyPlaying == null) {
      close();
    }
  }
}

class _PlatformPlaybackListener extends BaseAudioHandler with QueueHandler {
  final MultiAudioNotificationService service;

  _PlatformPlaybackListener(this.service);

  @override
  Future<void> play() => service.onPlayed();

  @override
  Future<void> pause() => service.onPaused();

  @override
  Future<void> stop() async {
    playbackState.add(PlaybackState());
    service.onClosed();
  }
}
