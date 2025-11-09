part of '../relax_sounds_view.dart';

class _SoundsTab extends StatelessWidget {
  const _SoundsTab({
    required this.viewModel,
  });

  final RelaxSoundsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RelaxSoundsProvider>(context);

    // split into 2 section for now.
    Iterable<RelaxSoundObject> musicSounds = RelaxSoundObject.musicSounds();
    Iterable<String> musicSoundUrls = musicSounds.map((e) => e.soundUrlPath);

    Iterable<RelaxSoundObject> relaxSounds = provider.relaxSounds.values;
    relaxSounds = relaxSounds.where((sound) => !musicSoundUrls.contains(sound.soundUrlPath));

    return CustomScrollView(
      controller: PrimaryScrollController.maybeOf(context),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            top: 16.0,
            left: MediaQuery.of(context).padding.left + 16.0,
            right: MediaQuery.of(context).padding.right + 16.0,
            bottom: 24.0,
          ),
          sliver: SliverAlignedGrid.count(
            crossAxisCount: MediaQuery.of(context).size.width ~/ 115,
            itemCount: musicSounds.length,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 16.0,
            itemBuilder: (context, index) {
              return buildSoundItem(
                context: context,
                relaxSounds: musicSounds,
                index: index,
                provider: provider,
              );
            },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left + 16.0,
            right: MediaQuery.of(context).padding.right + 16.0,
            bottom: 16.0,
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
        if (!context.read<InAppPurchaseProvider>().relaxSound)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(top: 8.0),
            sliver: SliverToBoxAdapter(
              child: ListTile(
                onTap: () => SpRewardSheet().show(context: context),
                trailing: const Icon(SpIcons.info),
                tileColor: Theme.of(context).colorScheme.readOnly.surface1,
                shape: RoundedSuperellipseBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                title: Text(tr('list_tile.share_relax_sound_to_social.title')),
                subtitle: SpMarkdownBody(
                  body: tr('list_tile.share_relax_sound_to_social.subtitle'),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
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
        if (selected && provider.getVolume(relaxSound) != null) _VolumeSlider(relaxSound: relaxSound),
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
      scaleActive: 0.95,
      effects: [SpTapEffectType.scaleDown],
      onTap: () => provider.toggleSound(relaxSound, context: context),
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
              Consumer<InAppPurchaseProvider>(
                builder: (context, iapProvider, child) {
                  return buildStatusIcon(iapProvider, provider, context, relaxSound);
                },
              ),
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

  Widget buildStatusIcon(
    InAppPurchaseProvider iapProvider,
    RelaxSoundsProvider provider,
    BuildContext context,
    RelaxSoundObject relaxSound,
  ) {
    PlayerState? state = provider.playerStateFor(relaxSound.soundUrlPath);

    if (!relaxSound.free && !iapProvider.relaxSound) {
      return Positioned(
        top: 8.0,
        right: 8.0,
        child: Icon(
          SpIcons.lock,
          color: ColorScheme.of(context).primary,
          size: 16.0,
        ),
      );
    }

    if (viewModel.downloaded(relaxSound)) return const SizedBox.shrink();
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
          SpIcons.download,
          color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
          size: 16.0,
        ),
      );
    }
  }
}
