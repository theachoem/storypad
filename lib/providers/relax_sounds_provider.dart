import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/core/services/multi_audio_notification_service.dart';
import 'package:storypad/core/services/multi_audio_player_service.dart';
import 'package:storypad/core/services/relax_sound_timer_service.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';

class RelaxSoundsProvider extends ChangeNotifier with DebounchedCallback {
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

  late final RelaxSoundsTimerService timerService = RelaxSoundsTimerService(
    onEnded: () {
      debugPrint("🎸 RelaxSoundsTimerService#onEnded");
      audioPlayersService.pauseAll();
    },
  );

  bool? _playing;
  bool get playing => _playing ?? false;

  // flag for UI to only show save mix button when mix does not exist.
  // to avoid saving dublicate mixes.
  bool? _canSaveMix;
  bool get canSaveMix => _canSaveMix ?? false;

  bool isSoundSelected(RelaxSoundObject sound) => audioPlayersService.exist(sound.soundUrlPath);
  bool isDownloading(PlayerState? state) =>
      state?.processingState == ProcessingState.loading || state?.processingState == ProcessingState.idle;

  double? getVolume(RelaxSoundObject sound) => audioPlayersService.getVolume(sound.soundUrlPath);
  void setVolume(RelaxSoundObject sound, double volume) {
    audioPlayersService.setVolume(sound.soundUrlPath, volume);
    notifyListeners();

    refreshCanSaveMix();
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

  Future<void> toggleSound(
    RelaxSoundObject sound, {
    required BuildContext context,
    double? initialVolume,
  }) async {
    Feedback.forTap(context);

    final iapProvider = context.read<InAppPurchaseProvider>();
    if (!sound.free && !iapProvider.relaxSound) return openAddOn(context);

    if (isSoundSelected(sound)) {
      await audioPlayersService.removeAnAudio(sound.soundUrlPath);
    } else {
      await audioPlayersService.playAnAudio(sound.soundUrlPath, initialVolume: initialVolume);
      audioPlayersService.playAll();
    }

    notifyListeners();

    refreshCanSaveMix();
  }

  Future<void> openAddOn(BuildContext context) async {
    return AddOnsRoute.pushAndNavigateTo(
      product: AppProduct.relax_sounds,
      context: context,
      fullscreenDialog: true,
    );
  }

  Future<void> playAll({
    required Map<RelaxSoundObject, double?> soundWithInitialVolume,
  }) async {
    audioPlayersService.removeAllAudios();

    for (var entry in soundWithInitialVolume.entries) {
      await audioPlayersService.playAnAudio(
        entry.key.soundUrlPath,
        initialVolume: entry.value,
      );
    }

    notifyListeners();
    refreshCanSaveMix();
  }

  void togglePlayPause() {
    if (_playing == null) return;
    if (playing) {
      audioPlayersService.pauseAll();
    } else {
      audioPlayersService.playAll();
    }

    refreshCanSaveMix();
  }

  void dismiss() {
    audioPlayersService.removeAllAudios();

    refreshCanSaveMix();
  }

  void refreshCanSaveMix() async {
    _canSaveMix = await findExistingMix(ignoreVolume: false) == null;
    notifyListeners();
  }

  Future<RelaxSoundMixModel?> findExistingMix({
    required bool ignoreVolume,
  }) async {
    final saved = await RelaxSoundMixModel.db.where().then((e) => e?.items) ?? [];

    final playing = selectedRelaxSounds
        .map((s) => "${s.soundUrlPath}:${ignoreVolume ? 1 : getVolume(relaxSounds[s.soundUrlPath]!)}")
        .toSet();

    return saved.where((mix) {
      final db = mix.sounds.map((s) => "${s.soundUrlPath}:${ignoreVolume ? 1 : s.volume}").toSet();
      return db.length == playing.length && db.containsAll(playing);
    }).firstOrNull;
  }

  @override
  void dispose() {
    audioPlayersService.dispose();
    super.dispose();
  }
}
