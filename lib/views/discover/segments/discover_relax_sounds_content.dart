import 'dart:io';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_floating_relax_sound_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

part 'local_widgets/volume_slider.dart';
part 'local_widgets/sound_icon_card.dart';
part 'local_widgets/license_text.dart';

class DiscoverRelaxSoundsContent extends StatelessWidget {
  const DiscoverRelaxSoundsContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!kHasRelaxSoundsFeature) return const SizedBox.shrink();

    final provider = Provider.of<RelaxSoundsProvider>(context);
    Iterable<RelaxSoundObject> relaxSounds = provider.relaxSounds.values;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const SpFloatingRelaxSoundsTile(),
      body: CustomScrollView(
        controller: PrimaryScrollController.maybeOf(context),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: 12.0,
              left: MediaQuery.of(context).padding.left + 16.0,
              right: MediaQuery.of(context).padding.right + 16.0,
              bottom: 32.0,
            ),
            sliver: SliverAlignedGrid.count(
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
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          const SliverToBoxAdapter(child: _LicenseText()),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 120.0)),
        ],
      ),
    );
  }

  Widget buildSoundItem({
    required BuildContext context,
    required Iterable<RelaxSoundObject> relaxSounds,
    required int index,
    required RelaxSoundsProvider provider,
  }) {
    final relaxSound = relaxSounds.elementAt(index);
    bool selected = provider.isSoundSelected(relaxSound);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        buildSoundCardContents(provider, relaxSound, selected, context),
        if (selected && provider.getVolume(relaxSound) != null) _VolumeSlider(relaxSound: relaxSound)
      ],
    );
  }

  Widget buildSoundCardContents(
    RelaxSoundsProvider provider,
    RelaxSoundObject relaxSound,
    bool selected,
    BuildContext context,
  ) {
    return SpTapEffect(
      effects: [SpTapEffectType.touchableOpacity],
      onTap: () async {
        await provider.toggleSound(relaxSound);
      },
      child: Column(
        spacing: 8.0,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SoundIconCard(
            relaxSound: relaxSound,
            selected: selected,
          ),
          Text(
            relaxSound.label,
            style: TextTheme.of(context).bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
