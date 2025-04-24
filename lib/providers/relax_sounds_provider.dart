import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/core/services/multi_audio_player_service.dart';
import 'package:storypad/core/services/relax_sound_timer_service.dart';

class RelaxSoundsProvider extends ChangeNotifier with WidgetsBindingObserver {
  RelaxSoundsProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  Map<String, RelaxSoundObject> get relaxSounds => RelaxSoundObject.defaultSoundsList();
  List<RelaxSoundObject> get selectedRelaxSounds {
    return audioPlayersService.audioUrlPaths.map((urlPath) {
      return relaxSounds[urlPath]!;
    }).toList();
  }

  PlayerState? playerStateFor(String urlPath) => audioPlayersService.playingStates[urlPath];
  late MultiAudioPlayersService audioPlayersService = MultiAudioPlayersService(onStateChanged: (bool? playing) {
    if (playing != null) {
      playing ? timerService.startIfNot() : timerService.pauseIfNot();
      _playing = playing;
    } else {
      timerService.setStopIn(null);
      timerService.pauseIfNot();
    }

    notifyListeners();
  });

  late RelaxSoundsTimerService timerService = RelaxSoundsTimerService(onEnded: () {
    debugPrint("🎸 RelaxSoundsTimerService#onEnded");
    audioPlayersService.pauseAll();
  });

  bool? _playing;
  bool get playing => _playing ?? false;

  bool isSoundSelected(RelaxSoundObject sound) => audioPlayersService.exist(sound.soundUrlPath);
  double? getVolume(RelaxSoundObject sound) => audioPlayersService.getVolume(sound.soundUrlPath);
  void setVolumn(RelaxSoundObject sound, double volumn) {
    audioPlayersService.setVolume(sound.soundUrlPath, volumn);
    notifyListeners();
  }

  void setStopIn(Duration duration) {
    timerService.setStopIn(duration);
    notifyListeners();
  }

  Future<void> toggleSound(RelaxSoundObject sound) async {
    if (isSoundSelected(sound)) {
      await audioPlayersService.removeAnAudio(sound.soundUrlPath);
    } else {
      await audioPlayersService.playAnAudio(sound.soundUrlPath);
      audioPlayersService.playAll();
    }

    notifyListeners();
  }

  void togglePlayPause() {
    if (_playing == null) return;
    if (playing) {
      audioPlayersService.pauseAll();
    } else {
      audioPlayersService.playAll();
    }
  }

  void dismiss() {
    audioPlayersService.removeAllAudios();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_playing == null) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        if (playing) audioPlayersService.pauseAll();
        break;
      case AppLifecycleState.resumed:
        if (!playing) audioPlayersService.playAll();
        break;
    }
  }

  @override
  void dispose() {
    audioPlayersService.dispose();
    super.dispose();
  }
}
