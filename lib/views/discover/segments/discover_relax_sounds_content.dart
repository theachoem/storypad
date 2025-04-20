import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/core/services/firestore_storage_service.dart';
import 'package:storypad/core/services/messenger_service.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_floating_relax_sound_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

part 'local_widgets/volume_slider.dart';
part 'local_widgets/sound_icon_card.dart';

class DiscoverRelaxSoundsContent extends StatelessWidget {
  const DiscoverRelaxSoundsContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!kHasRelaxSoundsFeature) return const SizedBox.shrink();

    final provider = Provider.of<RelaxSoundsProvider>(context);
    List<RelaxSoundObject> relaxSounds = provider.relaxSounds;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const SpFloatingRelaxSoundsTile(),
      body: Builder(builder: (context) {
        return AlignedGridView.count(
          padding: EdgeInsets.only(
            top: 12.0,
            left: MediaQuery.of(context).padding.left + 16.0,
            right: MediaQuery.of(context).padding.right + 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
          ),
          crossAxisCount: MediaQuery.of(context).size.width ~/ 115,
          itemCount: relaxSounds.length,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 16.0,
          itemBuilder: (context, index) {
            return buildSoundItem(
              context: context,
              relaxSounds: relaxSounds,
              index: index,
              provider: provider,
            );
          },
        );
      }),
    );
  }

  Widget buildSoundItem({
    required BuildContext context,
    required List<RelaxSoundObject> relaxSounds,
    required int index,
    required RelaxSoundsProvider provider,
  }) {
    final relaxSound = relaxSounds[index];
    bool selected = provider.isSoundSelected(relaxSound);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        buildSoundCardContents(provider, relaxSound, selected),
        if (selected && provider.getVolume(relaxSound) != null) _VolumeSlider(relaxSound: relaxSound)
      ],
    );
  }

  Widget buildSoundCardContents(
    RelaxSoundsProvider provider,
    RelaxSoundObject relaxSound,
    bool selected,
  ) {
    return SpSingleStateWidget.listen(
      initialValue: false,
      builder: (context, settingUp, notifier) {
        return SpTapEffect(
          effects: [SpTapEffectType.touchableOpacity],
          onTap: () async {
            if (!selected) notifier.value = true;
            if (await provider.audioPlayersService.getCachedFile(relaxSound.soundUrlPath) == null) {
              FirestoreStorageResponse result =
                  await provider.audioPlayersService.downloadFile(relaxSound.soundUrlPath);

              if (result.unauthorized && context.mounted) {
                MessengerService.of(context).showSnackBar('Authorized');
                return;
              }
            }

            await provider.toggleSound(relaxSound);
            notifier.value = false;
          },
          child: Column(
            spacing: 8.0,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SoundIconCard(
                relaxSound: relaxSound,
                selected: selected,
                settingUp: settingUp,
              ),
              Text(
                relaxSound.label,
                style: TextTheme.of(context).bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
