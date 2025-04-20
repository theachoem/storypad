import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/services/audio_player_service.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';

class MultiAudioPlayersService {
  final void Function(bool playing) onStateChanged;

  MultiAudioPlayersService({
    required this.onStateChanged,
  });

  final Map<String, AudioPlayerService> _players = {};
  final Map<String, bool> _playingStates = {};

  List<String> get audioUrlPaths => _players.keys.toList();

  bool exist(String url) => _players.keys.contains(url);
  double? getVolume(String soundUrl) => _players[soundUrl]?.getVolume();
  void setVolume(String soundUrl, double volume) => _players[soundUrl]?.setVolume(volume);

  void _notifyListeners() {
    onStateChanged(_playingStates.values.every((playing) => playing));
  }

  // make sure to download file from UI before playing.
  Future<void> playAnAudio(String url) async {
    final file = await getCachedFile(url);
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

  Future<File?> getCachedFile(String path) => FirestoreStorageService.instance.getCachedFile(path);
  Future<FirestoreStorageResponse> downloadFile(String path) => FirestoreStorageService.instance.downloadFile(path);

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
