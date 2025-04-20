import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/services/audio_player_service.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';

class MultiAudioPlayersService {
  final void Function(bool? playing) onStateChanged;

  MultiAudioPlayersService({
    required this.onStateChanged,
  });

  final Map<String, AudioPlayerService> _players = {};
  final Map<String, bool> _playingStates = {};

  List<String> get audioUrlPaths => _players.keys.toList();

  bool exist(String urlPath) => _players.keys.contains(urlPath);
  double? getVolume(String soundUrl) => _players[soundUrl]?.getVolume();
  void setVolume(String soundUrl, double volume) => _players[soundUrl]?.setVolume(volume);

  void _notifyListeners() {
    onStateChanged(_playingStates.isEmpty ? null : _playingStates.values.every((playing) => playing));
  }

  // make sure to download file from UI before playing.
  Future<void> playAnAudio(String urlPath) async {
    final file = await getCachedFile(urlPath);
    if (file == null) return;

    _playingStates[urlPath] ??= false;
    _players[urlPath] ??= _constructAudioService(urlPath, file);

    await _players[urlPath]!.play();
  }

  Future<void> removeAnAudio(String urlPath) async {
    await _players[urlPath]?.dispose();
    _players.remove(urlPath);
    _playingStates.remove(urlPath);

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

  Future<File?> getCachedFile(String urlPath) => FirestoreStorageService.instance.getCachedFile(urlPath);
  Future<FirestoreStorageResponse> downloadFile(String urlPath) =>
      FirestoreStorageService.instance.downloadFile(urlPath);

  AudioPlayerService _constructAudioService(String urlPath, File file) {
    return AudioPlayerService(
      file: file,
      onStateChanged: (PlayerState state) {
        debugPrint('🎸 AudioPlayerService#onStateChanged state:$state');
        _playingStates[urlPath] = state.playing;
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
