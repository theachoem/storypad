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
            SpSectionTitle(title: tr("general.appearance")),
            ThemeModeTile.globalTheme(weekday: 1),
            ColorSeedTile(),
            if (kStoryPad) const AppIconTile(),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.text")),
            FontSizeTile.globalTheme(weekday: 2),
            FontFamilyTile.globalTheme(weekday: 3),
            FontWeightTile.globalTheme(weekday: 4),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.general")),
            const LanguageTile(weekday: 5),
            buildAppLockTile(context, weekday: 6),
            if (kSupportQuickActions)
              ListTile(
                leading: const SpSettingIconBadge(weekday: 7, icon: SpIcons.home),
                title: Text(tr('page.home_quick_actions.title')),
                onTap: () => const HomeQuickActionsRoute().push(context),
              ),
            TimeFormatTile.globalTheme(weekday: 1),
            FirstDayOfWeekTile.globalTheme(weekday: 2),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.stories")),

            // ignore: prefer_const_constructors, no need to make sure locals switching work.
            StoryTilePreferencesTile(weekday: 3),

            // ignore: prefer_const_constructors, no need to make sure locals switching work.
            DefaultStoryPreferencesTile(weekday: 4),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.data")),
            ListTile(
              leading: const SpSettingIconBadge(weekday: 5, icon: SpIcons.import),
              title: Text(tr("page.backup_services.title")),
              onTap: () => const BackupServicesRoute().push(context),
            ),
            ListTile(
              leading: const SpSettingIconBadge(weekday: 6, icon: SpIcons.storage),
              title: Text(tr('page.storage_management.title')),
              onTap: () => const StorageManagementRoute().push(context),
            ),
            AssetCompressionTile.globalTheme(weekday: 7),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget buildAppLockTile(BuildContext context, {int weekday = 2}) {
    return Consumer<AppLockProvider>(
      builder: (context, appLockProvider, child) {
        return ListTile(
          leading: SpSettingIconBadge(weekday: weekday, icon: SpIcons.lock),
          title: Text(tr("page.app_lock.title")),
          subtitle: appLockProvider.hasAppLock ? Text(tr("general.enabled")) : null,
          onTap: () => AppLocksRoute().push(context),
        );
      },
    );
  }
}
