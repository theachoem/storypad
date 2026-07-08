import 'package:storypad/core/services/notifications/local_notification_service.dart';
import 'package:storypad/core/storages/device_preferences_storage.dart';

class NotificationInitializer {
  static Future<void> call() async {
    await LocalNotificationService.instance.init();

    // Reschedule on every launch so schedules stay consistent (e.g. across
    // timezone changes) and survive app data restore.
    await LocalNotificationService.instance.rescheduleAll(
      DevicePreferencesStorage.appInstance.preferences.reminders,
    );
  }
}
