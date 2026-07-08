import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/services/notifications/reminder_navigation_service.dart';
import 'package:storypad/core/services/on_this_day_prediction_service.dart';
import 'package:storypad/core/services/period_prediction_service.dart';
import 'package:storypad/core/storages/device_preferences_storage.dart';
import 'package:storypad/core/types/notification_channel.dart';
import 'package:storypad/core/types/reminder_type.dart';

/// Device-local scheduled reminders via flutter_local_notifications.
///
/// Reminders are per-device (not synced). Each [ReminderObject] can produce
/// several OS notifications — one per selected weekday — using a derived id so
/// each slot can be cancelled/rescheduled independently.
///
/// v1 uses inexact scheduling to avoid the SCHEDULE_EXACT_ALARM permission.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  // rescheduleAll() is called unawaited (see DevicePreferencesProvider) so its
  // Save/toggle caller isn't blocked on OS scheduling latency. That means two
  // calls can overlap if edits happen back-to-back; this version number ensures
  // a stale, still-in-flight call can never clobber a newer one — only the
  // most recently requested reschedule is allowed to finish applying its writes.
  int _rescheduleVersion = 0;

  // Chains reschedule runs so their cancelAll()+schedule work never overlaps —
  // without this, an older call's cancelAll() could complete after a newer
  // call had already scheduled notifications, wiping them out even though the
  // version check below would (correctly) stop the older call from
  // scheduling anything itself. Each run still checks the version first so a
  // call superseded before its turn comes up does no wasted native work.
  Future<void> _rescheduleQueue = Future<void>.value();

  bool get supported => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (navigatorKey != null) _navigatorKey = navigatorKey;
    if (_initialized || !supported) return;
    _initialized = true;

    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to the default (UTC) location; reminders still fire, just in UTC.
    }

    // The OS requires a default icon at init time, before any specific
    // notification (and its channel) is known — use the generic custom-reminder
    // icon as that fallback.
    final androidSettings = AndroidInitializationSettings(NotificationChannel.reminderCustom.androidIcon);
    // Shared by iOS and macOS — both use the same Darwin notification APIs.
    const darwinSettings = DarwinInitializationSettings(
      // Permission is requested explicitly on first enable, not at init.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: androidSettings, iOS: darwinSettings, macOS: darwinSettings),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Handle a tap that cold-launched the app.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final response = launchDetails!.notificationResponse;
      if (response != null) _onTap(response);
    }
  }

  /// Requests OS notification permission. Returns true when granted.
  Future<bool> requestPermission() async {
    if (!supported) return false;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }

    if (Platform.isMacOS) {
      final macOS = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      return await macOS?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }

    return false;
  }

  /// Cancels all reminder notifications and reschedules the enabled ones.
  Future<void> rescheduleAll(List<ReminderObject>? reminders) {
    if (!supported || !_initialized) return Future<void>.value();

    final version = ++_rescheduleVersion;

    // Chained onto the previous run (regardless of whether it's done yet) so
    // no two runs ever call cancelAll()/schedule concurrently — see
    // [_rescheduleQueue].
    final run = _rescheduleQueue.then((_) => _runReschedule(version, reminders));
    _rescheduleQueue = run;
    return run;
  }

  Future<void> _runReschedule(int version, List<ReminderObject>? reminders) async {
    // A newer reschedule request arrived before this one's turn came up —
    // skip it entirely rather than doing a cancelAll()+schedule pass whose
    // result would just be immediately superseded.
    if (version != _rescheduleVersion) return;

    await _plugin.cancelAll();
    for (final reminder in reminders ?? const <ReminderObject>[]) {
      // A newer reschedule request arrived while we were still working —
      // abandon this one so it can't overwrite the newer call's result.
      if (version != _rescheduleVersion) return;
      if (reminder.enabled) await _schedule(reminder);
    }
  }

  Future<void> _schedule(ReminderObject reminder) async {
    // Period reminders are one-shot: fired a few days before the predicted next
    // period, recomputed on each reschedule (app launch / reminder change).
    if (reminder.type == ReminderType.period) {
      await _schedulePeriod(reminder);
      return;
    }

    // On-this-day fires only on dates that actually have past memories —
    // local notifications can't check that at delivery time, so we precompute
    // matching dates and schedule one one-shot notification per date.
    if (reminder.type == ReminderType.onThisDay) {
      await _scheduleOnThisDay(reminder);
      return;
    }

    final details = _detailsFor(reminder.type);
    final payload = jsonEncode({'reminderId': reminder.id});

    // Content is baked into each repeating notification at schedule time and
    // reused for every real-world occurrence of that weekday slot until the
    // next reschedule (app launch or reminder edit) — that's what gives daily
    // reminders variety day-to-day (different slots can pick different copy),
    // rather than variety within a single slot's recurrences.
    for (final slot in reminder.scheduleSlots) {
      final weekday = slot == 0 ? null : slot;
      final (title, body) = await ReminderNavigationService.copyFor(reminder);
      await _plugin.zonedSchedule(
        id: _notificationId(reminder.id, slot),
        title: title,
        body: body,
        scheduledDate: _nextInstance(hour: reminder.hour, minute: reminder.minute, weekday: weekday),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: weekday == null ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    }
  }

  Future<void> _schedulePeriod(ReminderObject reminder) async {
    final predicted = await PeriodPredictionService.loadPredictedNextPeriodStart();
    if (predicted == null) return;

    final daysAhead = reminder.daysAhead ?? 2;
    final target = predicted.subtract(Duration(days: daysAhead));
    final scheduled = tz.TZDateTime(tz.local, target.year, target.month, target.day, reminder.hour, reminder.minute);

    // Skip when the reminder moment has already passed.
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    final (title, body) = await ReminderNavigationService.copyFor(reminder);
    await _plugin.zonedSchedule(
      id: _notificationId(reminder.id, 0),
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _detailsFor(reminder.type),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({'reminderId': reminder.id}),
      // No matchDateTimeComponents -> one-shot.
    );
  }

  Future<void> _scheduleOnThisDay(ReminderObject reminder) async {
    // Bounded horizon + result cap: keeps this a handful of cheap indexed
    // count() queries (see OnThisDayPredictionService) and keeps the number of
    // pending notifications well under the OS limits (iOS caps at 64 total).
    final dates = await OnThisDayPredictionService.loadUpcomingMemoryDates(
      horizonDays: 30,
      maxResults: 20,
    );
    if (dates.isEmpty) return;

    final details = _detailsFor(reminder.type);
    final payload = jsonEncode({'reminderId': reminder.id});
    final now = tz.TZDateTime.now(tz.local);

    for (final date in dates) {
      final scheduled = tz.TZDateTime(tz.local, date.year, date.month, date.day, reminder.hour, reminder.minute);
      if (!scheduled.isAfter(now)) continue;

      final (title, body) = await ReminderNavigationService.copyFor(reminder);
      await _plugin.zonedSchedule(
        id: _dateNotificationId(reminder.id, date),
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        // No matchDateTimeComponents -> one-shot.
      );
    }
  }

  /// Derived, stable OS notification id. `slot` is 0 (every day) or a weekday 1..7.
  int _notificationId(int reminderId, int slot) => reminderId * 10 + slot;

  /// Derived id for one-shot, date-specific notifications (on-this-day). Uses a
  /// much larger multiplier than [_notificationId] so the two id spaces never
  /// collide for realistic reminder ids.
  int _dateNotificationId(int reminderId, DateTime date) => reminderId * 100000 + date.month * 100 + date.day;

  tz.TZDateTime _nextInstance({required int hour, required int minute, int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (weekday != null) {
      while (scheduled.weekday != weekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(Duration(days: weekday == null ? 1 : 7));
    }

    return scheduled;
  }

  NotificationDetails _detailsFor(ReminderType type) {
    final channel = type.channel;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.channelID,
        channel.channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: channel.androidIcon,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    int? reminderId;
    try {
      reminderId = (jsonDecode(payload) as Map<String, dynamic>)['reminderId'] as int?;
    } catch (_) {
      return;
    }
    if (reminderId == null) return;

    final reminder = DevicePreferencesStorage.appInstance.preferences.reminders
        ?.where((r) => r.id == reminderId)
        .firstOrNull;
    if (reminder == null) return;

    ReminderNavigationService.instance.handleTap(reminder, _navigatorKey);
  }
}
