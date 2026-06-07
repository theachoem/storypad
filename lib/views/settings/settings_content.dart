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
            buildDayColorTile(context),
            if (kStoryPad) const AppIconTile(),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.text")),
            FontSizeTile.globalTheme(weekday: 3),
            FontFamilyTile.globalTheme(weekday: 4),
            FontWeightTile.globalTheme(weekday: 5),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.general")),
            const LanguageTile(weekday: 6),
            buildAppLockTile(context, weekday: 7),
            if (kSupportQuickActions) QuickActionsTile(),
            TimeFormatTile.globalTheme(weekday: 2),
            FirstDayOfWeekTile.globalTheme(weekday: 3),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.stories")),

            // ignore: prefer_const_constructors, no need to make sure locals switching work.
            StoryTilePreferencesTile(weekday: 4),

            // ignore: prefer_const_constructors, no need to make sure locals switching work.
            DefaultStoryPreferencesTile(weekday: 5),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.data")),
            ListTile(
              leading: const SpSettingIconBadge(weekday: 6, icon: SpIcons.import),
              title: Text(tr("page.backup_services.title")),
              onTap: () => const BackupServicesRoute().push(context),
            ),
            ListTile(
              leading: const SpSettingIconBadge(weekday: 7, icon: SpIcons.storage),
              title: Text(tr('page.storage_management.title')),
              onTap: () => const StorageManagementRoute().push(context),
            ),
            AssetCompressionTile.globalTheme(weekday: 1),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget buildDayColorTile(BuildContext context) {
    return Consumer<InAppPurchaseProvider>(
      builder: (context, inAppPurchaseProvider, child) {
        final locked = !inAppPurchaseProvider.isProUser;

        return ListTile(
          trailing: locked ? const Icon(SpIcons.lock) : null,
          leading: const SpSettingIconBadge(weekday: 2, icon: SpIcons.theme),
          title: Text(tr('list_tile.day_colors.title')),
          onTap: () => const DayColorsRoute().push(context),
        );
      },
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
