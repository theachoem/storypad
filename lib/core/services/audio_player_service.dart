import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final String urlPath;
  final void Function(PlayerState state) onStateChanged;

  late double _volume = _player.volume;

  AudioPlayerService({
    required this.urlPath,
    required this.onStateChanged,
  }) {
    _player.playerStateStream.listen((state) {
      if (_disposed) return;

      debugPrint('🎻 AudioPlayerService#onStateChanged ${basename(urlPath)}: $state');
      onStateChanged(state);
    });
  }

  bool? _setLoop;
  bool? _setAudioSource;
  Completer<bool>? _setupCompleter;
  String? _downloadUrl;

  double getVolume() => _volume;
  void setVolume(double volume) {
    _volume = volume;
    _player.setVolume(volume);
  }

  Future<bool> _setup() async {
    if (_setupCompleter != null) return _setupCompleter!.future;

    _setupCompleter = Completer();
    _setLoop ??= await _player.setLoopMode(LoopMode.one).then((e) => true);
    _downloadUrl ??= await FirestoreStorageService.instance.getDownloadURL(urlPath);

    if (_downloadUrl == null) {
      _setupCompleter?.complete(false);
      return false;
    } else {
      final audioSource = LockCachingAudioSource(Uri.parse(_downloadUrl!));
      _setAudioSource ??= await _player.setAudioSource(await audioSource.resolve()).then((e) => true);
      _setupCompleter?.complete(true);

      return true;
    }
  }

  Future<void> play() async {
    bool success = await _setup();

    // no need to wait for play.
    if (success) _player.play();
  }

  Future<void> pause() async {
    bool success = await _setup();
    if (success) await _player.pause();
  }

  bool _disposed = false;
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    // If not stop before dispose, it will raise:
    // Bad state: Cannot add new events after calling close
    await _player.stop();
    await _player.dispose();
  }
}
