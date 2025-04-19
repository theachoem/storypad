import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';
import 'package:storypad/widgets/sp_cache_file_downloader_builder.dart';
import 'package:storypad/widgets/sp_floating_relax_sound_tile.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class DiscoverRelaxSoundsContent extends StatelessWidget {
  const DiscoverRelaxSoundsContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RelaxSoundsProvider>(context);
    List<RelaxSoundObject> relaxSounds = provider.relaxSounds;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const SpFloatingRelaxSoundsTile(),
      body: Builder(builder: (context) {
        return AlignedGridView.count(
          padding: EdgeInsets.only(
            top: 4.0,
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
          ),
          crossAxisCount: MediaQuery.of(context).size.width ~/ 115,
          itemCount: relaxSounds.length,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 16.0,
          itemBuilder: (context, index) {
            final relaxSound = relaxSounds[index];
            bool selected = provider.isSoundSelected(index);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                SpTapEffect(
                  effects: [SpTapEffectType.touchableOpacity],
                  onTap: () => provider.toggleSound(index),
                  child: Column(
                    spacing: 8.0,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      buildSoundIconCard(context, relaxSound, selected),
                      Text(
                        relaxSound.label,
                        style: TextTheme.of(context).bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 2.0,
                    left: 16.0,
                    right: 16.0,
                    child: Slider(
                      divisions: 5,
                      allowedInteraction: SliderInteraction.tapAndSlide,
                      thumbColor: Theme.of(context).colorScheme.surface,
                      value: provider.getVolumn(index),
                      padding: EdgeInsets.zero,
                      onChanged: (value) => provider.setVolumn(index, value),
                    ),
                  )
              ],
            );
          },
        );
      }),
    );
  }

  Widget buildSoundIconCard(
    BuildContext context,
    RelaxSoundObject relaxSound,
    bool selected,
  ) {
    return AnimatedContainer(
      curve: Curves.ease,
      duration: Durations.short2,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: selected ? ColorScheme.of(context).readOnly.surface2 : null,
        border: Border.all(
          color: selected ? ColorScheme.of(context).primary : Theme.of(context).dividerColor,
        ),
      ),
      child: SpCacheFileDownloaderBuilder(
        fileUrl: relaxSound.svgIconUrl,
        builder: (context, file, failed) {
          if (file == null) {
            return SpLoopAnimationBuilder(
              duration: const Duration(seconds: 1),
              reverseDuration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return SizedBox(
                  height: 48,
                  child: Icon(
                    Icons.music_note_outlined,
                    color: Color.lerp(
                      ColorScheme.of(context).onSurface.withValues(alpha: 0.1),
                      ColorScheme.of(context).onSurface.withValues(alpha: 0.3),
                      value,
                    ),
                  ),
                );
              },
            );
          }

          return SvgPicture.file(
            file,
            semanticsLabel: relaxSound.label,
            height: 48,
            colorFilter: ColorFilter.mode(
              selected ? ColorScheme.of(context).primary : ColorScheme.of(context).onSurface,
              BlendMode.srcIn,
            ),
          );
        },
      ),
    );
  }
}
