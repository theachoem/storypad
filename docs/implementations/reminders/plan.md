# Reminders (Local Notifications) — Implementation Design

Status: **In progress.** Local-only, free for all users. No user-facing doc yet
— per the docs convention, `docs/features/reminders.md` is only added once this
feature is fully complete and stable (see `CLAUDE.md`/`AGENTS.md`).

## Why

Storypad has no reminder feature. Existing `NotificationChannel` /
`multi_audio_notification_service.dart` are `audio_service` media notifications
for relaxing sounds — not user reminders. There is no
`flutter_local_notifications`, scheduling, or permission handling.

A nudge-to-write reminder is the highest-impact retention feature for a
journaling app. Goals: **local-only** (offline, no backend, data stays on
device), **free**, and structured for both simple built-in reminders and
flexible user-created custom reminders (à la Day One) without UI clutter.

## Decisions

- Local notifications only (no FCM / server push).
- No paywall gating.
- Two categories: **built-in** (simple on/off) + **custom** (user-created).
- Custom reminder = custom message + optional journal template + optional tags;
  tap creates a prefilled new journal, else just opens the app.
- Time model = time-of-day + weekday checkboxes (only Monday checked = weekly).
- **Exact alarms deferred** — v1 uses inexact scheduling (avoids
  `SCHEDULE_EXACT_ALARM` permission friction). Add opt-in "Exact time" later.

## Reused infrastructure (do NOT rebuild)

| Need                          | Reuse                                                                                                                                              |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| New journal w/ prefill on tap | `EditStoryRoute` (`initialTagIds`, `galleryTemplate`, `template`, `initialYear/Month/Day`) — `lib/views/stories/edit/edit_story_view.dart`         |
| "On this day" query           | `SearchFilterObject(month, day)` like `ThrowbackViewModel`; route via `ThrowbackRoute`                                                             |
| Tags                          | `TagsProvider` (`allTags`, `getEmojiTag`) + `TagDbModel`                                                                                           |
| Period history                | `EventDbModel.db` — `lib/core/databases/models/event_db_model.dart`                                                                                |
| Settings persistence          | `DevicePreferencesObject` / `DevicePreferencesStorage` / `DevicePreferencesProvider` (setX → copyWith → `storage.writeObject` → `notifyListeners`) |
| Settings sub-page pattern     | `DayColorsRoute`/`DayColorsView` (`lib/views/day_colors/`) + `BaseRoute`                                                                           |
| Settings tile/section         | `lib/views/settings/settings_content.dart` (`SpSectionTitle`)                                                                                      |
| Icons / dialogs / i18n        | `SpIcons.*`, `adaptive_dialog`, `tr()` (never a condition inside `tr()`)                                                                           |

## Model objects

### `ReminderType` — `lib/core/types/reminder_type.dart`

```dart
enum ReminderType {
  daily,      // built-in: nudge to write; tap -> new blank journal
  onThisDay,  // built-in: fires only if past entries exist today; tap -> Throwback
  period,     // built-in: N days before predicted next period; tap -> period calendar
  custom;     // user-created: custom msg + optional template/tags

  bool get isBuiltin => this != custom;
}
```

### `ReminderObject` — `lib/core/objects/reminder_object.dart`

One object type for both categories (built-ins are singletons; custom can be
many). `@CopyWith() @JsonSerializable()` + `.g.dart`. Time stored as
`hour`/`minute` ints (TimeOfDay isn't JSON-serializable). Fields kept public to
avoid the copy_with_extension v15 private-field gotcha.

```dart
@CopyWith()
@JsonSerializable()
class ReminderObject {
  final int id;                     // stable; also seeds notification id(s)
  final ReminderType type;
  final bool enabled;

  final int hour;                   // 0–23
  final int minute;                 // 0–59
  final List<int> weekdays;         // 1=Mon..7=Sun; empty = every day

  // custom only
  final String? message;            // notification body; default per type if null
  final int? templateId;            // -> EditStoryRoute.template
  final String? galleryTemplateId;  // -> EditStoryRoute.galleryTemplate
  final List<int>? tagIds;          // -> EditStoryRoute.initialTagIds

  // period only
  final int? daysAhead;             // remind N days before predicted period (default 2)

  ReminderObject({
    required this.id,
    required this.type,
    this.enabled = true,
    this.hour = 21,
    this.minute = 0,
    this.weekdays = const [],
    this.message,
    this.templateId,
    this.galleryTemplateId,
    this.tagIds,
    this.daysAhead,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
  bool get isEveryDay => weekdays.isEmpty;

  Map<String, dynamic> toJson() => _$ReminderObjectToJson(this);
  factory ReminderObject.fromJson(Map<String, dynamic> json) =>
      _$ReminderObjectFromJson(json);
}
```

### `DevicePreferencesObject` — add one field (+ regen `.g.dart`)

```dart
final List<ReminderObject>? reminders; // null = never configured
```

Optional constructor param, no default → stays null. Backward compatible.

### `NotificationChannel` — add channels

Alongside `relaxingSound`: `reminderDaily`, `reminderOnThisDay`,
`reminderPeriod`, `reminderCustom` (each with `channelID` + `channelName`), so
users can mute categories independently from media playback.

### Notification payload

JSON payload carrying `reminderId`. On tap, look up the reminder in
`DevicePreferencesProvider.preferences.reminders` and route by `type`.

## Service / logic

### `LocalNotificationService` — `lib/core/services/notifications/local_notification_service.dart`

Singleton (mirrors existing `*_service.dart`):

- `init()` — plugin + timezone init + tap handler.
- `requestPermission()` — iOS + Android 13+ `POST_NOTIFICATIONS`.
- `rescheduleAll(List<ReminderObject>)` — cancel then reschedule enabled ones.
- `_schedule(ReminderObject)` — one `zonedSchedule` per weekday using
  `DateTimeComponents.dayOfWeekAndTime` (or `.time` when `isEveryDay`). Derived
  notification id = `reminder.id * 10 + weekday`. **Inexact** Android mode.

### `ReminderInitializer` — `lib/core/initializers/notification_initializer.dart`

`static Future<void> call()` → `LocalNotificationService.init()` then
`rescheduleAll(prefs.reminders ?? [])`. Wire into `lib/main.dart` after
`OnboardingInitializer.call()`, guarded off Linux.

### Tap routing (by `type`)

- `daily` → `EditStoryRoute(today)`
- `onThisDay` → `ThrowbackRoute(month, day = today)`
- `period` → period calendar route
- `custom` → template/tags set: `EditStoryRoute(galleryTemplate/template,
initialTagIds)`; else open app

### Conditional built-ins

Local notifications can't run Dart code at delivery time, so neither of these
can decide "skip today" live — both precompute matching dates ahead of time and
schedule one-shot notifications only for those dates, recomputed on every
reschedule (app launch / reminder change).

- `onThisDay`: `OnThisDayPredictionService` (`lib/core/services/`) scans a
  30-day horizon and returns up to 20 dates that have past entries, using
  indexed `count()` queries on `StoryDbModel.db` (month/day/type — no row
  hydration, no events join), so a full scan is cheap (well under the cost of
  a single `where()` call) and safe to run on every launch. One one-shot
  notification is scheduled per matching date; tap still routes to
  `ThrowbackRoute`. The pure date-selection logic is unit-tested without a
  database (`test/core/services/on_this_day_prediction_service_test.dart`).
- `period`: predict next period from `EventDbModel` history (avg gap between
  period start dates), schedule `daysAhead` before. Pure-Dart
  `PeriodPredictionService` (`lib/core/services/`). Only when period calendar on.

Both bypass `ReminderObject.weekdays` entirely (it's meaningless for one-shot,
date-driven reminders) — the edit screen hides the weekday picker for these two
types (`EditReminderView._supportsWeekdays`).

Notification ids: weekday-based schedules use `reminderId * 10 + slot`;
date-based one-shots use `reminderId * 100000 + month * 100 + day` — a much
larger multiplier so the two id spaces can't collide.

## Provider — `DevicePreferencesProvider`

Follow the `setX` pattern; call `LocalNotificationService.rescheduleAll` after
each mutation:

- `List<ReminderObject> get reminders`
- `upsertReminder(ReminderObject)`
- `deleteReminder(int id)`
- `toggleReminder(int id, bool enabled)`
- built-in getters (e.g. `ReminderObject? get dailyReminder`)

## UI (MVVM) — `lib/views/reminders/`

`reminders_view.dart` (+ `RemindersRoute extends BaseRoute`),
`reminders_content.dart`, `reminders_view_model.dart`, `local_widgets/`.
Modeled on `lib/views/day_colors/`.

- **List**: "Built-in" section (Daily, On this day, Period[if enabled]) as switch
  tiles with time/weekday subtitle; "Custom" section listing reminders as human
  sentences (`"Write every day at 9:00 PM"`, `"Review 💡 #idea every Mon"`) + a
  single **"+ Add reminder"** button.
- **Add/Edit custom**: message, time picker, weekday chips (empty = every day),
  optional template picker, optional tag picker. Only relevant fields shown.
- **Permission**: request on first enable; if denied, adaptive dialog → system
  settings.
- **Settings entry**: tile in `settings_content.dart` under "general" →
  `RemindersRoute`; `SpIcons.*`. Optionally run `refresh-settings-colors` after.

## Native config

- **Android** (`docs/development/android-config.md`): `POST_NOTIFICATIONS`,
  notification icon, `flutter_local_notifications` receivers,
  `RECEIVE_BOOT_COMPLETED` for reboot persistence. **No** `SCHEDULE_EXACT_ALARM`.
- **iOS** (`docs/development/ios-config.md`): request authorization + AppDelegate
  setup.

## Packages (check `docs/development/dependencies.md` first)

`flutter_local_notifications`, `timezone` (+ `flutter_timezone` if needed).

## Build order

1. Foundation: packages + native config + `LocalNotificationService` +
   `ReminderInitializer` + `NotificationChannel`.
2. Model: `ReminderType`, `ReminderObject` (+regen),
   `DevicePreferencesObject.reminders` (+regen), provider setters.
3. Built-in **Daily** end-to-end — verify fires.
4. **Custom** reminders: list UI, add/edit, prefill on tap.
5. **On this day** + **Period** (+ `PeriodPredictionService`).
6. Settings tile + translations.
7. Once the feature is fully complete and stable: add `docs/features/reminders.md`.

## Verification

- **Unit**: `PeriodPredictionService`, `ReminderObject` JSON round-trip,
  weekday→id derivation (`docs/development/testing-basics.md`).
- **Manual (device required):** daily reminder fires + tap opens new journal;
  custom w/ template+tag prefills; toggling off cancels; weekday-only fires only
  that day; denied permission → dialog; Android reboot persists schedules.
- **Static**: `flutter analyze` clean; no `Icons.*`/`CupertinoIcons.*`; no
  conditions inside `tr()`.
