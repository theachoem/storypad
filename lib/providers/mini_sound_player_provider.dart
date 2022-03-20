import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:spooky/core/file_manager/managers/sound_file_manager.dart';
import 'package:spooky/core/models/sound_model.dart';
import 'package:spooky/core/routes/sp_router.dart';
import 'package:spooky/core/services/loop_audio_seamlessly.dart';
import 'package:spooky/core/services/messenger_service.dart';
import 'package:spooky/core/types/sound_type.dart';

class MiniSoundPlayerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SoundFileManager manager = SoundFileManager();
  late final Map<SoundType, LoopAudioSeamlessly> audioPlayers;
  late final ValueNotifier<bool> currentlyPlayingNotifier;
  late final ValueNotifier<double> playerExpandProgressNotifier;
  late final MiniplayerController controller;

  final miniplayerPercentageDeclaration = 0.2;
  final double playerMinHeight = 48 + 16 * 2;
  final double playerMaxHeight = 232;

  List<SoundModel> get currentSounds {
    List<SoundModel> sounds = [];
    for (SoundType type in SoundType.values) {
      SoundModel? sound = currentSound(type);
      if (sound != null) {
        sounds.add(sound);
      }
    }
    return sounds;
  }

  SoundModel? currentSound(SoundType type) => audioPlayers[type]?.currentSound;
  // SoundType get baseSoundType => SoundType.sound;

  MiniSoundPlayerProvider() {
    currentlyPlayingNotifier = ValueNotifier(false);
    playerExpandProgressNotifier = ValueNotifier(playerMinHeight);
    controller = MiniplayerController();
    load();
    initPlayers();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    currentlyPlayingNotifier.dispose();
    playerExpandProgressNotifier.dispose();
    controller.dispose();
    audioPlayers.forEach((key, value) => value.dispose());
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
  }

  void initPlayers() {
    audioPlayers = {};
    for (SoundType type in SoundType.values) {
      audioPlayers[type] = LoopAudioSeamlessly();
    }
  }

  List<SoundModel>? downloadedSounds;
  Future<void> load() async {
    downloadedSounds = await manager.downloadedSound();
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      notifyListeners();
    });
  }

  void showDownloadMoreSound(BuildContext context) {
    MessengerService.instance.showSnackBar(
      "Download more sounds",
      action: SnackBarAction(
        label: "All sounds",
        onPressed: () {
          Navigator.of(context).pushNamed(SpRouter.soundList.path);
        },
      ),
    );
  }

  void updatePlayingState() {
    currentlyPlayingNotifier.value = hasPlaying;
  }

  void play(SoundModel sound) async {
    audioPlayers[sound.type]?.play(sound);
    updatePlayingState();
    notifyListeners();
  }

  void playPreviousNext({
    required BuildContext context,
    required bool previous,
  }) {
    for (SoundType type in SoundType.values) {
      _playPreviousNext(
        type: type,
        context: context,
        previous: previous,
      );
    }
  }

  void _playPreviousNext({
    required SoundType type,
    required BuildContext context,
    required bool previous,
  }) {
    List<SoundModel>? sounds = downloadedSounds?.where((e) => e.type == type).toList();
    if (sounds?.isNotEmpty == true) {
      int index = sounds!.indexWhere((e) => currentSound(type)?.fileName == e.fileName);
      int validatedIndex = (previous ? index - 1 : index + 1) % sounds.length;
      play(sounds[validatedIndex]);
      // if (validatedIndex == 0) {
      //   showDownloadMoreSound(context);
      // }
    }
  }

  void onDismissed() {
    audioPlayers.forEach((key, value) => value.stop());
    updatePlayingState();

    // avoid show barier
    playerExpandProgressNotifier.value = playerMinHeight;
    notifyListeners();
  }

  void togglePlayPause() {
    if (currentlyPlayingNotifier.value) {
      for (SoundType type in SoundType.values) {
        pause(type);
      }
    } else {
      for (SoundType type in SoundType.values) {
        resume(type);
      }
    }
  }

  void stop(SoundType type) {
    if (currentSound(type) != null) {
      audioPlayers[type]?.stop();
      updatePlayingState();
    }
  }

  void pause(SoundType type) {
    if (currentSound(type) != null) {
      audioPlayers[type]?.pause();
      updatePlayingState();
    }
  }

  void resume(SoundType type) {
    if (currentSound(type) != null) {
      audioPlayers[type]?.resume();
      updatePlayingState();
    }
  }

  bool get hasPlaying {
    return SoundType.values.map((type) {
      return audioPlayers[type]?.playing == true;
    }).where((playing) {
      return playing;
    }).isEmpty;
  }

  double offset(double percentage) {
    double offset = (percentage - playerMinHeight) / (playerMaxHeight - playerMinHeight);
    return offset;
  }

  double valueFromPercentageInRange({required final double min, max, percentage}) {
    return percentage * (max - min) + min;
  }

  double percentageFromValueInRange({required final double min, max, value}) {
    return (value - min) / (max - min);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        for (SoundType type in SoundType.values) {
          resume(type);
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        for (SoundType type in SoundType.values) {
          pause(type);
        }
        break;
    }
  }
}
