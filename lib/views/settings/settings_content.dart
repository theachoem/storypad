part of 'settings_view.dart';

class _SettingsContent extends StatelessWidget {
  const _SettingsContent(this.viewModel);

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.settings.title")),
      ),
      body: ListView(
        children: [
          ...[
            SpSectionTitle(title: tr("general.general")),
            ListTile(
              leading: const SpSettingIconBadge(weekday: 1, icon: SpIcons.theme),
              title: Text(tr("general.appearance")),
              onTap: () => const AppearanceRoute().push(context),
            ),
            buildAppLockTile(context, weekday: 2),
            if (LocalNotificationService.instance.supported) ...[
              ListTile(
                leading: const SpSettingIconBadge(weekday: 3, icon: SpIcons.alarm),
                title: Text(tr('page.reminders.title')),
                onTap: () => const RemindersRoute().push(context),
              ),
            ],
            ListTile(
              leading: const SpSettingIconBadge(weekday: 4, icon: SpIcons.googleDrive),
              title: Text(tr("general.data_backup")),
              onTap: () => const DataBackupRoute().push(context),
            ),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.region")),
            const LanguageTile(weekday: 5),
            TimeFormatTile.globalTheme(weekday: 6),
            FirstDayOfWeekTile.globalTheme(weekday: 7),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: tr("general.stories")),
            DefaultStoryPreferencesTile(weekday: 1),
            MyTemplatesTile(weekday: 2),
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
