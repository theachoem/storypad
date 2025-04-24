import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/services/audio_player_service.dart';

class MultiAudioPlayersService {
  final void Function(bool? playing) onStateChanged;

  MultiAudioPlayersService({
    required this.onStateChanged,
  });

  final Map<String, AudioPlayerService> _players = {};
  final Map<String, PlayerState> _playingStates = {};
  Map<String, PlayerState> get playingStates => _playingStates;

  List<String> get audioUrlPaths => _players.keys.toList();

  bool exist(String urlPath) => _players.keys.contains(urlPath);
  double? getVolume(String soundUrl) => _players[soundUrl]?.getVolume();
  void setVolume(String soundUrl, double volume) => _players[soundUrl]?.setVolume(volume);

  void _notifyListeners() {
    debugPrint('🎸 MultiAudioPlayersService#_notifyListeners $_playingStates');
    onStateChanged(playingStates.values.any((e) => e.playing));
  }

  // make sure to download file from UI before playing.
  Future<void> playAnAudio(String urlPath) async {
    _playingStates[urlPath] ??= PlayerState(false, ProcessingState.idle);
    _players[urlPath] ??= _constructAudioService(urlPath);

    await _players[urlPath]!.play();
  }

  Future<void> removeAnAudio(String urlPath) async {
    await _players[urlPath]?.dispose();
    _players.remove(urlPath);
    _playingStates.remove(urlPath);

    _notifyListeners();
  }

  void removeAllAudios() {
    for (var service in _players.values) {
      service.dispose();
    }
    _players.clear();
    _playingStates.clear();
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

  AudioPlayerService _constructAudioService(String urlPath) {
    return AudioPlayerService(
      urlPath: urlPath,
      onStateChanged: (PlayerState state) {
        // stop listen if key is removed.
        if (_players[urlPath] == null) return;

        _playingStates[urlPath] = state;
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
