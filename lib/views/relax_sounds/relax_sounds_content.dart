part of 'relax_sounds_view.dart';

class _RelaxSoundsContent extends StatelessWidget {
  const _RelaxSoundsContent(this.viewModel);

  final RelaxSoundsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.relaxSound) return const SizedBox.shrink();

    final provider = Provider.of<RelaxSoundsProvider>(context);
    Iterable<RelaxSoundObject> relaxSounds = provider.relaxSounds.values;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(tr('page.relax_sounds.title')),
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
      ),
      bottomNavigationBar: const SpFloatingRelaxSoundsTile(),
      body: CustomScrollView(
        controller: PrimaryScrollController.maybeOf(context),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: CupertinoSheetRoute.hasParentSheet(context) ? 8.0 : 20,
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
