part of 'settings_view.dart';

class _SettingsContent extends StatelessWidget {
  const _SettingsContent(this.viewModel);

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("page.settings.title")),
      ),
      body: ListView(
        children: [
          ...[
            SpSectionTitle(title: context.tr("general.general")),
            ListTile(
              leading: const SpSettingIconBadge(weekday: 1, icon: SpIcons.theme),
              title: Text(context.tr("general.customization")),
              onTap: () => const AppearanceRoute().push(context),
            ),
            buildAppLockTile(context, weekday: 2),
            if (LocalNotificationService.instance.supported) ...[
              ListTile(
                leading: const SpSettingIconBadge(weekday: 3, icon: SpIcons.alarm),
                title: Text(context.tr('page.reminders.title')),
                onTap: () => const RemindersRoute().push(context),
              ),
            ],
            ListTile(
              leading: const SpSettingIconBadge(weekday: 4, icon: SpIcons.googleDrive),
              title: Text(context.tr("general.data_backup")),
              onTap: () => const DataBackupRoute().push(context),
            ),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: context.tr("general.region")),
            const LanguageTile(weekday: 5),
            TimeFormatTile.globalTheme(weekday: 6),
            FirstDayOfWeekTile.globalTheme(weekday: 7),
          ],
          ...[
            const Divider(),
            SpSectionTitle(title: context.tr("general.stories")),
            const DefaultStoryPreferencesTile(weekday: 1),
            const MyTemplatesTile(weekday: 2),
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
          title: Text(context.tr("page.app_lock.title")),
          subtitle: appLockProvider.hasAppLock ? Text(context.tr("general.enabled")) : null,
          onTap: () => AppLocksRoute().push(context),
        );
      },
    );
  }
}
