import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/services/notifications/local_notification_service.dart';
import 'package:storypad/core/types/reminder_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/reminders/edit/sp_edit_reminder_sheet.dart';
import 'package:storypad/views/reminders/edit_custom_reminder/edit_custom_reminder_view.dart';

/// Requests OS notification permission, showing an explanatory dialog when denied.
/// Returns true when notifications are allowed.
Future<bool> ensureNotificationPermission(BuildContext context) async {
  final granted = await LocalNotificationService.instance.requestPermission();
  if (granted) return true;

  if (context.mounted) {
    await showOkAlertDialog(
      context: context,
      title: tr('dialog.notification_permission_denied.title'),
      message: tr('dialog.notification_permission_denied.message'),
    );
  }
  return false;
}

class RemindersViewModel extends ChangeNotifier with DisposeAwareMixin {
  final DevicePreferencesProvider devicePreferencesProvider;

  RemindersViewModel({required BuildContext context})
    : devicePreferencesProvider = context.read<DevicePreferencesProvider>() {
    // Scoped subscription instead of watching DevicePreferencesProvider
    // directly — that provider is shared across the whole app, so watching it
    // broadly would rebuild far more than just this screen on every reminder edit.
    devicePreferencesProvider.addListenerForReminderChanges(notifyListeners);
  }

  @override
  void dispose() {
    devicePreferencesProvider.removeListenerForReminderChanges(notifyListeners);
    super.dispose();
  }

  /// Built-in reminders (daily/on-this-day/period) edit via a compact sheet.
  Future<void> openBuiltinEditor(BuildContext context, ReminderObject reminder) async {
    await SpEditReminderSheet(reminder: reminder).show(context: context);
  }

  /// Custom reminders have more fields (message, template, tags), so they get
  /// their own full page instead of the compact sheet.
  Future<void> openCustomEditor(BuildContext context, ReminderObject reminder) async {
    await EditCustomReminderRoute(reminder: reminder).push(context);
  }

  Future<void> addCustomReminder(BuildContext context) async {
    final provider = context.read<DevicePreferencesProvider>();

    final granted = await ensureNotificationPermission(context);
    if (!granted || !context.mounted) return;

    final reminder = ReminderObject(
      id: provider.nextCustomReminderId,
      type: ReminderType.custom,
      enabled: true,
    );

    await EditCustomReminderRoute(reminder: reminder, isNew: true).push(context);
  }
}
