import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/types/notification_channel.dart';

enum ReminderType {
  /// Built-in: nudge to write; tap opens a new blank journal for today.
  daily,

  /// Built-in: fires only if past entries exist today; tap opens Throwback.
  onThisDay,

  /// Built-in: fires N days before the predicted next period; tap opens the period calendar.
  period,

  /// User-created: custom message + optional template/tags; tap creates a prefilled journal.
  custom;

  bool get isBuiltin => this != ReminderType.custom;

  NotificationChannel get channel {
    switch (this) {
      case ReminderType.daily:
        return NotificationChannel.reminderDaily;
      case ReminderType.onThisDay:
        return NotificationChannel.reminderOnThisDay;
      case ReminderType.period:
        return NotificationChannel.reminderPeriod;
      case ReminderType.custom:
        return NotificationChannel.reminderCustom;
    }
  }

  /// Only meaningful for built-in types — custom reminders use the user's own
  /// message as their title instead (see EditCustomReminderViewModel).
  String get title {
    switch (this) {
      case ReminderType.daily:
        return tr('reminder.daily.title');
      case ReminderType.onThisDay:
        return tr('reminder.on_this_day.title');
      case ReminderType.period:
        return tr('reminder.period.title');
      case ReminderType.custom:
        throw UnsupportedError('ReminderType.custom has no generic title — use the reminder\'s own message.');
    }
  }

  /// Only meaningful for built-in types — custom reminders don't show a
  /// generic description anywhere in the UI.
  String get description {
    switch (this) {
      case ReminderType.daily:
        return tr('reminder.daily.description');
      case ReminderType.onThisDay:
        return tr('reminder.on_this_day.description');
      case ReminderType.period:
        return tr('reminder.period.description');
      case ReminderType.custom:
        throw UnsupportedError('ReminderType.custom has no generic description.');
    }
  }

  /// Stable id for this type's single notification action button, also used
  /// as the Darwin notification category identifier. `null` means no action
  /// button is shown (custom reminders — tapping the body is enough).
  String? get notificationActionId {
    switch (this) {
      case ReminderType.daily:
        return 'write_now';
      case ReminderType.onThisDay:
        return 'view';
      case ReminderType.period:
        return 'view_calendar';
      case ReminderType.custom:
        return 'view';
    }
  }

  /// Label for [notificationActionId]. Every action does exactly what
  /// tapping the notification body already does (see
  /// ReminderNavigationService) — it's a shortcut, not a distinct behavior.
  String? get notificationActionLabel {
    switch (this) {
      case ReminderType.daily:
        return tr('button.write_now');
      case ReminderType.onThisDay:
      case ReminderType.custom:
        return tr('button.view');
      case ReminderType.period:
        return tr('button.view_calendar');
    }
  }
}
