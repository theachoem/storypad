part of 'reminders_view.dart';

class _RemindersContent extends StatelessWidget {
  const _RemindersContent(this.viewModel);

  final RemindersViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // Read-only: this widget rebuilds when RemindersViewModel notifies (scoped
    // to reminder changes via addListenerForReminderChanges), not by watching
    // DevicePreferencesProvider directly — that provider is shared across the
    // whole app and would cause far more rebuilds than needed here.
    final provider = context.read<DevicePreferencesProvider>();
    final periodEnabled = provider.enablePeriodCalendar(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('page.reminders.title'))),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildBuiltinTile(context, provider, ReminderType.daily, SpIcons.newStory),
          _buildBuiltinTile(context, provider, ReminderType.onThisDay, SpIcons.history),
          if (periodEnabled) _buildBuiltinTile(context, provider, ReminderType.period, SpIcons.calendar),
          const SizedBox(height: 8.0),
          const Divider(height: 1),
          const SizedBox(height: 4.0),
          for (final reminder in provider.customReminders) _buildCustomTile(context, reminder),
          ListTile(
            leading: const Icon(SpIcons.add),
            title: Text(tr('page.reminders.add_reminder')),
            onTap: () => viewModel.addCustomReminder(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBuiltinTile(
    BuildContext context,
    DevicePreferencesProvider provider,
    ReminderType type,
    IconData icon,
  ) {
    final reminder = provider.reminderOfType(type);
    final enabled = reminder?.enabled ?? false;

    void openSheet() => viewModel.openBuiltinEditor(context, reminder ?? ReminderObject.builtin(type));

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
      leading: Icon(icon),
      title: Text(type.title),
      subtitle: Text(
        enabled && reminder != null ? _builtinEnabledSummary(context, type, reminder) : type.description,
      ),
      // The switch reflects the true enabled state but doesn't toggle directly —
      // tapping it (like tapping the tile) opens the sheet, where the real
      // switch lives. Avoids the old "must enable before you can configure" trap.
      trailing: Switch.adaptive(value: enabled, onChanged: (_) => openSheet()),
      onTap: openSheet,
    );
  }

  Widget _buildCustomTile(BuildContext context, ReminderObject reminder) {
    // Guaranteed non-empty: EditCustomReminderViewModel requires a message
    // before a custom reminder can be saved.
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
      leading: const Icon(SpIcons.alarm),
      title: Text(reminder.message!.trim(), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(reminderScheduleSummary(context, time: reminder.timeOfDay, weekdays: reminder.weekdays.toSet())),
      onTap: () => viewModel.openCustomEditor(context, reminder),
      // Edit is redundant here (tapping the tile already opens the editor);
      // delete moved into the edit page's AppBar, keeping this trailing
      // consistent with the built-in tiles (switch only).
      trailing: Switch.adaptive(
        value: reminder.enabled,
        onChanged: (value) async {
          if (value && !await ensureNotificationPermission(context)) return;
          if (context.mounted) {
            await context.read<DevicePreferencesProvider>().toggleReminder(reminder.id, value);
          }
        },
      ),
    );
  }

  /// Daily/custom fire on a weekday schedule; on-this-day/period fire on
  /// precomputed one-shot dates, so their summary just states the time.
  String _builtinEnabledSummary(BuildContext context, ReminderType type, ReminderObject reminder) {
    final time = MaterialLocalizations.of(context).formatTimeOfDay(reminder.timeOfDay);
    switch (type) {
      case ReminderType.daily:
        return reminderScheduleSummary(context, time: reminder.timeOfDay, weekdays: reminder.weekdays.toSet());
      case ReminderType.onThisDay:
        return tr('reminder.summary.around_time', namedArgs: {'S_TIME': time});
      case ReminderType.period:
        return tr('reminder.summary.around_time', namedArgs: {'S_TIME': time});
      case ReminderType.custom:
        return reminderScheduleSummary(context, time: reminder.timeOfDay, weekdays: reminder.weekdays.toSet());
    }
  }
}
