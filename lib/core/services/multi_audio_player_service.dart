import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/services/audio_player_service.dart';
import 'package:storypad/core/services/task_queue_service.dart';

class MultiAudioPlayersService {
  final void Function(bool playing) onStateChanged;

  MultiAudioPlayersService({
    required this.onStateChanged,
  });

  final Map<String, AudioPlayerService> _players = {};
  final Map<String, bool> _playingStates = {};

  List<String> get audioUrls => _players.keys.toList();

  bool exist(String url) => _players.keys.contains(url);
  double? getVolume(String soundUrl) => _players[soundUrl]?.getVolume();
  void setVolume(String soundUrl, double volume) => _players[soundUrl]?.setVolume(volume);

  void _notifyListeners() {
    onStateChanged(_playingStates.values.every((playing) => playing));
  }

  Future<void> playAnAudio(String url) async {
    final file = await getSingleFile(url);
    if (file == null) return;

    _playingStates[url] ??= false;
    _players[url] ??= _constructAudioService(url, file);

    await _players[url]!.play();
  }

  Future<void> removeAnAudio(String url) async {
    _players[url]?.dispose();
    _players.remove(url);
    _playingStates.remove(url);

    _notifyListeners();
  }

  void playAll() {
    for (var p in _players.values) {
      p.play();
    }
  }

  void pauseAll() {
    for (var player in _players.values) {
      player.pause();
    }
  }

  final TaskQueueService _queue = TaskQueueService();
  Future<File?> getSingleFile(String url) async {
    await _queue.addTask(() async {
      try {
        await CachedNetworkImageProvider.defaultCacheManager.getSingleFile(url);
      } catch (e) {
        debugPrint("$runtimeType#getSingleFile failed");
      }
    });

    return CachedNetworkImageProvider.defaultCacheManager.getFileFromCache(url).then((e) => e?.file);
  }

  AudioPlayerService _constructAudioService(String url, File file) {
    return AudioPlayerService(
      file: file,
      onStateChanged: (PlayerState state) {
        debugPrint('🎸 AudioPlayerService#onStateChanged state:$state');
        _playingStates[url] = state.playing;
        _notifyListeners();
      },
    );
  }

  void dispose() {
    for (var player in _players.values) {
      player.dispose();
    }
  }
}
