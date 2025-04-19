import 'package:flutter/material.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/core/services/multi_audio_player_service.dart';
import 'package:storypad/core/services/relax_sound_timer_service.dart';

class RelaxSoundsProvider extends ChangeNotifier with WidgetsBindingObserver {
  RelaxSoundsProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  List<RelaxSoundObject> get relaxSounds => RelaxSoundObject.defaultSoundsList();

  List<RelaxSoundObject> get selectedRelaxSounds {
    return relaxSounds.where((e) {
      return audioPlayersService.audioUrls.contains(e.soundUrl);
    }).toList();
  }

  late MultiAudioPlayersService audioPlayersService = MultiAudioPlayersService(onStateChanged: (playing) {
    playing ? timerService.startIfNot() : timerService.pauseIfNot();
    _playing = playing;

    debugPrint("🎸 MultiAudioPlayersService#onStateChanged playing: $playing");
    notifyListeners();
  });

  late RelaxSoundsTimerService timerService = RelaxSoundsTimerService(onEnded: () {
    debugPrint("🎸 RelaxSoundsTimerService#onEnded");
    audioPlayersService.pauseAll();
  });

  bool _playing = false;
  bool get playing => _playing;

  bool isSoundSelected(RelaxSoundObject sound) => audioPlayersService.exist(sound.soundUrl);
  double? getVolume(RelaxSoundObject sound) => audioPlayersService.getVolume(sound.soundUrl);
  void setVolumn(RelaxSoundObject sound, double volumn) {
    audioPlayersService.setVolume(sound.soundUrl, volumn);
    notifyListeners();
  }

  void setStopIn(Duration duration) {
    timerService.setStopIn(duration);
    notifyListeners();
  }

  Future<void> toggleSound(RelaxSoundObject sound) async {
    if (audioPlayersService.exist(sound.soundUrl)) {
      await audioPlayersService.removeAnAudio(sound.soundUrl);
    } else {
      await audioPlayersService.playAnAudio(sound.soundUrl);
    }

    notifyListeners();
  }

  void togglePlayPause() {
    if (playing) {
      audioPlayersService.pauseAll();
    } else {
      audioPlayersService.playAll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

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
