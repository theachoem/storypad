part of '../relax_sounds_view.dart';

class _MixesTab extends StatelessWidget {
  const _MixesTab({
    required this.viewModel,
  });

  final RelaxSoundsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RelaxSoundsProvider>(context);

    if (viewModel.mixes?.isEmpty == true) {
      return LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: constraints.maxHeight,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12.0,
                children: [
                  const Icon(SpIcons.musicNote, size: 32.0),
                  Text(
                    tr('page.relax_sounds.mixes_empty_message'),
                    textAlign: TextAlign.center,
                    style: TextTheme.of(context).bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }

    return ReorderableListView.builder(
      itemCount: viewModel.mixes?.length ?? 0,
      padding: EdgeInsets.only(
        top: 12.0,
        left: MediaQuery.of(context).padding.left + 12.0,
        right: MediaQuery.of(context).padding.right + 12.0,
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
      ),
      onReorder: (int oldIndex, int newIndex) => viewModel.reorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final mix = viewModel.mixes![index];

        return buildMixTile(
          mix: mix,
          provider: provider,
          context: context,
        );
      },
    );
  }

  Widget buildMixTile({
    required RelaxSoundMixModel mix,
    required RelaxSoundsProvider provider,
    required BuildContext context,
  }) {
    Iterable<RelaxSoundObject> sounds = mix.sounds.map((e) {
      return provider.relaxSounds[e.soundUrlPath];
    }).whereType<RelaxSoundObject>();

    Color backgroundColor = ColorFromDayService(context: context).get(sounds.lastOrNull?.dayColor ?? 1)!;

    return Container(
      key: ValueKey(mix.id),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: SpFadeIn.fromBottom(
        child: ListTile(
          onTap: () => viewModel.playMix(context, mix, sounds),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(8.0),
          ),
          tileColor: backgroundColor,
          textColor: Theme.of(context).colorScheme.onPrimary,
          title: Text(mix.name),
          contentPadding: const EdgeInsets.only(left: 20.0, right: 0.0, top: 8.0, bottom: 8.0),
          trailing: SpPopupMenuButton(
            dyGetter: (dy) => dy + 56,
            items: (context) {
              return [
                SpPopMenuItem(
                  title: tr('button.rename'),
                  onPressed: () => viewModel.rename(context, mix),
                ),
                SpPopMenuItem(
                  title: tr('button.delete'),
                  titleStyle: TextStyle(color: ColorScheme.of(context).error),
                  onPressed: () => viewModel.delete(context, mix),
                ),
              ];
            },
            builder: (callback) {
              return IconButton(
                color: Theme.of(context).colorScheme.onPrimary,
                icon: const Icon(SpIcons.moreVert),
                onPressed: callback,
              );
            },
          ),
          leading: Stack(
            children: List.generate(sounds.length, (index) {
              final relaxSound = sounds.elementAt(index);

              Widget child = const SizedBox(height: 40, width: 40);
              if (index == sounds.length - 1) {
                child = buildSoundIcon(relaxSound);
              }

              return Transform.rotate(
                angle: (sounds.length - 1 - index) * 25,
                child: Transform.scale(
                  scale: 1.0 - (sounds.length - 1 - index) * 0.1,
                  child: Transform.translate(
                    offset: Offset(
                      (sounds.length - 1 - index) * -5,
                      (sounds.length - 1 - index) * -5,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget buildSoundIcon(RelaxSoundObject relaxSound) {
    return SpFirestoreStorageDownloaderBuilder(
      filePath: relaxSound.svgIconUrlPath,
      builder: (context, file, failed) {
        if (file == null) return const _SoundIconLoading();

        return SvgPicture.file(
          file,
          semanticsLabel: relaxSound.label,
          height: 40,
          colorFilter: ColorFilter.mode(
            ColorScheme.of(context).onSurface,
            BlendMode.srcIn,
          ),
        );
      },
    );
  }
}
