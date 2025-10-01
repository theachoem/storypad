part of '../relax_sounds_view.dart';

class _SoundsTab extends StatelessWidget {
  const _SoundsTab({
    required this.viewModel,
  });

  final RelaxSoundsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RelaxSoundsProvider>(context);
    final relaxSounds = provider.relaxSounds.values;

    return CustomScrollView(
      controller: PrimaryScrollController.maybeOf(context),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            top: 16.0,
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
          Stack(
            children: [
              _SoundIconCard(
                relaxSound: relaxSound,
                selected: selected,
              ),
              if (!viewModel.downloaded(relaxSound)) buildDownloadIcon(provider, context, relaxSound),
            ],
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

  Widget buildDownloadIcon(RelaxSoundsProvider provider, BuildContext context, RelaxSoundObject relaxSound) {
    PlayerState? state = provider.playerStateFor(relaxSound.soundUrlPath);

    if (state != null && state.playing == true) return const SizedBox.shrink();
    if (provider.isDownloading(state)) {
      return const Positioned(
        top: 8.0,
        right: 8.0,
        child: SizedBox.square(
          dimension: 16.0,
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    } else {
      return Positioned(
        top: 8.0,
        right: 8.0,
        child: Icon(
          Icons.download,
          color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
          size: 16.0,
        ),
      );
    }
  }
}
