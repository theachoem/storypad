import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/services/cloud_storage/cloud_storage_service.dart';

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

  double getVolume() => _volume;
  void setVolume(double volume) {
    _volume = volume;
    _player.setVolume(volume);
  }

  Future<bool> _setup() async {
    if (_setupCompleter != null) return _setupCompleter!.future;

    final completer = Completer<bool>();
    _setupCompleter = completer;

    try {
      _setLoop ??= await _player.setLoopMode(LoopMode.one).then((e) => true);

      File? cachedFile = CloudStorageService.instance.getCachedFile(urlPath);
      cachedFile ??= await CloudStorageService.instance.downloadFile(urlPath).then((e) => e.file);

      if (cachedFile != null && !_disposed) {
        _setAudioSource ??= await _player.setFilePath(cachedFile.path).then((value) => true);
        completer.complete(true);
        return true;
      } else {
        completer.complete(false);
        return false;
      }
    } catch (error) {
      debugPrint('🎻 AudioPlayerService#_setup ${basename(urlPath)} failed: $error');
      // Allow future retries instead of hanging every subsequent call on a broken setup.
      _setAudioSource = null;
      _setupCompleter = null;
      completer.complete(false);
      return false;
    }
  }

  Future<void> play() async {
    bool success = await _setup();
    if (!success || _disposed) return;

    // no need to wait for play.
    _player.play().catchError((error) {
      debugPrint('🎻 AudioPlayerService#play ${basename(urlPath)} failed: $error');
    });
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
