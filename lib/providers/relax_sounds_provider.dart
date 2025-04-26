import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/core/services/multi_audio_notification_service.dart';
import 'package:storypad/core/services/multi_audio_player_service.dart';
import 'package:storypad/core/services/relax_sound_timer_service.dart';

class RelaxSoundsProvider extends ChangeNotifier {
  Map<String, RelaxSoundObject> get relaxSounds => RelaxSoundObject.defaultSoundsList();
  String get selectedSoundsLabel => selectedRelaxSounds.map((e) => e.label).join(", ");
  List<RelaxSoundObject> get selectedRelaxSounds {
    return audioPlayersService.audioUrlPaths.map((urlPath) {
      return relaxSounds[urlPath]!;
    }).toList();
  }

  PlayerState? playerStateFor(String urlPath) => audioPlayersService.playingStates[urlPath];
  late final MultiAudioPlayersService audioPlayersService = MultiAudioPlayersService(
    onStateChanged: (bool? playing) async {
      if (playing != null) {
        playing ? timerService.startIfNot() : timerService.pauseIfNot();
        _playing = playing;
      } else {
        timerService.setStopIn(null);
        timerService.pauseIfNot();
      }

      refreshAppNotification();
      notifyListeners();
    },
  );

  late final _notificationService = MultiAudioNotificationService(
    onPlayed: () async => audioPlayersService.playAll(),
    onPaused: () async => audioPlayersService.pauseAll(),
    onClosed: () async => audioPlayersService.removeAllAudios(),
  );

  late final RelaxSoundsTimerService timerService = RelaxSoundsTimerService(onEnded: () {
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
    refreshAppNotification();
  }

  void refreshAppNotification() {
    return _notificationService.notifyUser(
      playingStates: audioPlayersService.playingStates,
      stopIn: timerService.stopIn,
      title: selectedSoundsLabel,
      backgroundUrlPath: selectedRelaxSounds.lastOrNull?.background.urlPath,
      artist: selectedRelaxSounds.map((e) => e.artist).join(", "),
    );
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
  void dispose() {
    audioPlayersService.dispose();
    super.dispose();
  }
}
