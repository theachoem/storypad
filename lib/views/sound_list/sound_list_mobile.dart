part of sound_list_view;

class _SoundListMobile extends StatelessWidget {
  final SoundListViewModel viewModel;
  const _SoundListMobile(this.viewModel);

  @override
  Widget build(BuildContext context) {
    List<SoundType> types = SoundType.values.reversed.toList();
    return Scaffold(
      appBar: buildAppBar(context),
      extendBody: true,
      body: CustomScrollView(
        slivers: List.generate(
          types.length,
          (index) {
            return buildSounds(context, types[index], index);
          },
        ),
      ),
    );
  }

  MorphingAppBar buildAppBar(BuildContext context) {
    return MorphingAppBar(
      leading: SpPopButton(),
      title: SpAppBarTitle(),
      actions: [
        Consumer<MiniSoundPlayerProvider>(
          child: SpIconButton(
            tooltip: "Stop",
            icon: Icon(Icons.stop_circle_outlined, color: M3Color.of(context).error),
            onPressed: () {
              context.read<MiniSoundPlayerProvider>().onDismissed();
            },
          ),
          builder: (context, provider, child) {
            return SpAnimatedIcons(
              firstChild: child!,
              secondChild: const SizedBox.shrink(),
              showFirst: provider.hasPlaying,
            );
          },
        ),
        Consumer<MiniSoundPlayerProvider>(
          child: SpIconButton(
            tooltip: "Listen with mini player",
            icon: Icon(Icons.branding_watermark, color: M3Color.of(context).primary),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          builder: (context, provider, child) {
            return SpAnimatedIcons(
              firstChild: child!,
              secondChild: const SizedBox.shrink(),
              showFirst: provider.hasPlaying,
            );
          },
        ),
        SpPopupMenuButton(items: (context) {
          return [
            SpPopMenuItem(
              title: "Play in Background",
              leadingIconData: viewModel.playSoundInBackground ? Icons.check_box : Icons.check_box_outline_blank,
              onPressed: () {
                viewModel.toggleBackgroundSound();
              },
            ),
          ];
        }, builder: (callback) {
          return SpIconButton(
            icon: Icon(Icons.more_vert),
            onPressed: callback,
          );
        }),
      ],
    );
  }

  Widget buildSounds(
    BuildContext context,
    SoundType type,
    int index,
  ) {
    List<SoundModel>? sounds = viewModel.soundsMap[type];
    return SliverStickyHeader(
      header: buildHeader(
        context: context,
        text: type.name.capitalize,
        type: type,
      ),
      sliver: SliverPadding(
        padding: EdgeInsets.only(bottom: index == SoundType.values.length - 1 ? kToolbarHeight * 2 : 0.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              SoundModel sound = sounds![index];
              bool downloaded = viewModel.fileManager.downloaded(sound);
              double fileSize = (sound.fileSize / 100000).roundToDouble() / 10;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: M3Color.dayColorsOf(context)[index % 6 + 1],
                  child: Consumer<MiniSoundPlayerProvider>(
                    builder: (context, provider, child) {
                      bool playing = provider.currentSound(sound.type)?.fileName == sound.fileName;
                      return SpAnimatedIcons(
                        firstChild: Icon(Icons.pause, color: M3Color.of(context).onPrimary),
                        secondChild: Icon(Icons.music_note, color: M3Color.of(context).onPrimary),
                        showFirst: playing,
                      );
                    },
                  ),
                ),
                title: Text(sound.soundName.capitalize),
                subtitle: Text("$fileSize mb"),
                trailing: downloaded ? null : Icon(Icons.download),
                onTap: () {
                  onSoundPressed(
                    context,
                    downloaded,
                    sound.type,
                    sound,
                  );
                },
              );
            },
            childCount: sounds?.length ?? 0,
          ),
        ),
      ),
    );
  }

  Future<void> onSoundPressed(
    BuildContext context,
    bool downloaded,
    SoundType type,
    SoundModel sound,
  ) async {
    UserProvider userProvider = context.read<UserProvider>();
    List<SoundModel> downloadedSounds = await viewModel.fileManager.downloadedSound();
    MiniSoundPlayerProvider provider = context.read<MiniSoundPlayerProvider>();
    if (downloaded) {
      if (provider.currentSound(type)?.fileName != sound.fileName) {
        provider.play(sound);
      } else {
        provider.stop(sound.type);
      }
    } else {
      if (userProvider.purchased(ProductAsType.relexSound) ||
          downloadedSounds.where((element) => element.type == type).isEmpty) {
        String? message = await MessengerService.instance
            .showLoading(future: () async => viewModel.download(sound), context: context);
        provider.load();
        MessengerService.instance.showSnackBar(message ?? "Fail");
      } else {
        MessengerService.instance.showSnackBar(
          "Purchase to download more.",
          action: SnackBarAction(
            label: "Add-ons",
            onPressed: () {
              Navigator.of(context).pushNamed(SpRouter.addOn.path);
            },
          ),
        );
      }
    }
  }

  Widget buildHeader({
    required BuildContext context,
    required String text,
    required SoundType type,
  }) {
    MiniSoundPlayerProvider provider = context.read<MiniSoundPlayerProvider>();
    AudioPlayer? player = provider.audioPlayers[type]?.player;
    return Material(
      elevation: 1.0,
      child: SpPopupMenuButton(
        dxGetter: (dx) => MediaQuery.of(context).size.width,
        dyGetter: (dy) => dy + kToolbarHeight + 8.0,
        items: (context) {
          double volumn = player?.volume ?? 1.0;
          return List.generate(4, (index) {
            double _volumn = (index + 1) * 25;
            return SpPopMenuItem(
              title: _volumn.toInt().toString(),
              trailingIconData: volumn * 100 == _volumn ? Icons.check : null,
              onPressed: () {
                player?.setVolume(_volumn / 100);
              },
            );
          });
        },
        builder: (callback) {
          return ListTile(
            onTap: callback,
            title: Text(text),
            tileColor: Theme.of(context).appBarTheme.backgroundColor,
            trailing: StreamBuilder<double>(
              stream: player?.volumeStream,
              builder: (context, snapshot) {
                double volumn = player?.volume ?? 1.0;
                IconData iconData;
                if (volumn == 0.0) {
                  iconData = Icons.volume_mute;
                } else if (volumn <= 0.5) {
                  iconData = Icons.volume_down;
                } else {
                  iconData = Icons.volume_up;
                }
                return Icon(iconData);
              },
            ),
          );
        },
      ),
    );
  }
}
