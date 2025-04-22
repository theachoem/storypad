import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/helpers/path_helper.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final File file;
  final void Function(PlayerState state) onStateChanged;

  late double _volumn = _player.volume;

  AudioPlayerService({
    required this.file,
    required this.onStateChanged,
  }) {
    _player.playerStateStream.listen((state) {
      debugPrint('🎻 AudioPlayerService#onStateChanged ${basename(file.path)}: $state');
      onStateChanged(state);
    });
  }

  bool? _setLoop;
  bool? _setAudioSource;
  Completer? _setupCompleter;

  double getVolume() => _volumn;
  void setVolume(double volume) {
    _volumn = volume;
    _player.setVolume(volume);
  }

  Future<void> setup() async {
    if (_setupCompleter != null) return _setupCompleter?.future;

    _setupCompleter = Completer();
    _setLoop ??= await _player.setLoopMode(LoopMode.one).then((e) => true);
    _setAudioSource ??= await _player.setAudioSource(AudioSource.file(file.path)).then((e) => true);

    _setupCompleter?.complete(true);
  }

  Future<void> play() async {
    await setup();

    // no need to wait for play.
    _player.play();
  }

  Future<void> pause() async {
    await setup();
    await _player.pause();
  }

  Future<void> dispose() async {
    // If not stop before dispose, it will raise:
    // Bad state: Cannot add new events after calling close
    await _player.stop();
    await _player.dispose();
  }
}
