part of 'settings_view.dart';

class _SettingsContent extends StatelessWidget {
  const _SettingsContent(this.viewModel);

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.settings.title")),
        actions: [
          SpPopupMenuButton(
            items: (context) {
              return [
                SpPopMenuItem(
                  leadingIconData: SpIcons.refresh,
                  title: tr("button.reset"),
                  onPressed: () {
                    context.read<DevicePreferencesProvider>().reset();
                  },
                ),
              ];
            },
            builder: (callback) {
              return IconButton(
                tooltip: tr("button.more_options"),
                icon: const Icon(SpIcons.moreVert),
                onPressed: callback,
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ...[
            SpSectionTitle(title: tr("general.general")),
            const LanguageTile(),
            buildAppLockTile(context),
            TimeFormatTile.globalTheme(),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.appearance")),
            ThemeModeTile.globalTheme(),
            const ColorSeedTile(),
            if (kStoryPad) const AppIconTile(),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.text")),
            FontSizeTile.globalTheme(),
            FontFamilyTile.globalTheme(),
            FontWeightTile.globalTheme(),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.advanced")),
            const StoryTilePreferencesTile(),
            const DefaultStoryPreferencesTile(),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget buildAppLockTile(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.lock),
      title: Text(tr("page.app_lock.title")),
      onTap: () => AppLocksRoute().push(context),
    );
  }
}
