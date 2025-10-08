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
          const LanguageTile(),
          buildAppLockTile(context),
          const Divider(),
          ThemeModeTile.globalTheme(),
          const ColorSeedTile(),
          const Divider(),
          FontSizeTile.globalTheme(),
          FontFamilyTile.globalTheme(),
          FontWeightTile.globalTheme(),
          TimeFormatTile.globalTheme(),
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
