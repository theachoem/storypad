import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/relax_sound_model.dart';
import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/mixins/list_reorderable.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';
import 'package:storypad/views/relax_sounds/edit_mix/edit_mix_view.dart';
import 'relax_sounds_view.dart';

class RelaxSoundsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final RelaxSoundsRoute params;

  RelaxSoundsViewModel({
    required this.params,
  }) {
    load();
  }

  List<RelaxSoundMixModel>? mixes;

  Future<void> load() async {
    mixes = await RelaxSoundMixModel.db.where().then((value) => value?.items) ?? [];
    notifyListeners();
  }

  void saveMix(BuildContext context) async {
    DateTime now = DateTime.now();

    RelaxSoundsProvider provider = context.read<RelaxSoundsProvider>();
    List<String> audioUrlPaths = provider.audioPlayersService.audioUrlPaths;

    List<RelaxSoundModel> sounds = [];
    for (String soundUrlPath in audioUrlPaths) {
      sounds.add(RelaxSoundModel(
        soundUrlPath: soundUrlPath,
        volume: provider.getVolume(provider.relaxSounds[soundUrlPath]!) ?? 0.5,
      ));
    }

    // save to existing mix with different volumn when exist.
    RelaxSoundMixModel? existingMix = await provider.findExistingMix(ignoreVolume: true);
    await RelaxSoundMixModel.db.set(
      RelaxSoundMixModel(
        id: existingMix?.id ?? now.millisecondsSinceEpoch,
        name: provider.selectedSoundsLabel,
        sounds: sounds,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await load();

    provider.refreshCanSaveMix();
  }

  Future<void> delete(BuildContext context, RelaxSoundMixModel mix) async {
    await RelaxSoundMixModel.db.delete(mix.id);
    await load();

    if (context.mounted) context.read<RelaxSoundsProvider>().refreshCanSaveMix();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (mixes == null) return;

    mixes = mixes!.reorder(oldIndex: oldIndex, newIndex: newIndex);
    notifyListeners();

    int length = mixes!.length;
    for (int i = 0; i < length; i++) {
      final item = mixes!.elementAt(i);
      if (item.index != i) {
        await RelaxSoundMixModel.db.set(item.copyWith(index: i, updatedAt: DateTime.now()));
      }
    }

    await load();
  }

  void playMix(
    BuildContext context,
    RelaxSoundMixModel mix,
    Iterable<RelaxSoundObject> sounds,
  ) async {
    await context.read<RelaxSoundsProvider>().playAll(soundWithInitialVolume: {
      for (var sound in sounds)
        sound: mix.sounds.where((saved) => saved.soundUrlPath == sound.soundUrlPath).firstOrNull?.volume
    });
  }

  Future<void> rename(BuildContext context, RelaxSoundMixModel mix) async {
    Object? result = await EditMixRoute(mix: mix).push(context);

    if (result is List && result.first is String) {
      await RelaxSoundMixModel.db.set(
        mix.copyWith(
          name: result.first,
          updatedAt: DateTime.now(),
        ),
      );
      await load();
    }
  }
}
