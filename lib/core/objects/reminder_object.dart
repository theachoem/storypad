import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/types/reminder_type.dart';

part 'reminder_object.g.dart';

/// A single reminder configuration, device-local (stored in DevicePreferencesObject).
///
/// Covers both built-in reminders (daily/onThisDay/period — singletons) and
/// user-created custom reminders (many). Time is stored as [hour]/[minute] ints
/// because TimeOfDay isn't JSON-serializable. Fields are kept public to avoid the
/// copy_with_extension v15+ private-field gotcha.
@CopyWith()
@JsonSerializable()
class ReminderObject {
  /// Stable id; also seeds the derived OS notification id(s).
  final int id;

  @JsonKey(unknownEnumValue: ReminderType.custom)
  final ReminderType type;

  final bool enabled;

  /// 0–23
  final int hour;

  /// 0–59
  final int minute;

  /// 1=Mon .. 7=Sun. Empty = every day.
  final List<int> weekdays;

  // ---- custom only ----

  /// User-entered reminder text — set only for custom reminders. Despite the
  /// name, [ReminderNavigationService.copyFor] uses it as the notification
  /// *title* for custom reminders (matching how it's shown in the reminders
  /// list), with a fixed generic body; it plays no role for built-in types,
  /// which get their title/body from [ReminderNotificationCopyService].
  final String? message;

  /// Custom template id -> EditStoryRoute.template.
  final int? templateId;

  /// Gallery template id -> EditStoryRoute.galleryTemplate.
  final String? galleryTemplateId;

  /// -> EditStoryRoute.initialTagIds.
  final List<int>? tagIds;

  // ---- period only ----

  /// Remind this many days before the predicted period. Defaults to 2 when null.
  final int? daysAhead;

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

  /// 1..7 (Mon..Sun) — the full week.
  static const List<int> allWeekdays = [1, 2, 3, 4, 5, 6, 7];

  /// Selecting every day and selecting no day both mean "every day", so both
  /// collapse to the same canonical empty list — there's only one data point
  /// for "every day", not two that happen to behave the same.
  static List<int> normalizeWeekdays(Iterable<int> weekdays) {
    final unique = weekdays.toSet();
    if (unique.isEmpty || unique.length >= allWeekdays.length) return const [];
    return unique.toList()..sort();
  }

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
  bool get isEveryDay => weekdays.isEmpty;

  /// The weekday "slots" this reminder schedules against (1..7). Empty weekdays
  /// means a single every-day schedule, represented here by a single 0 slot.
  List<int> get scheduleSlots => isEveryDay ? const [0] : (weekdays.toSet().toList()..sort());

  /// Factory for a built-in reminder with sensible defaults.
  ///
  /// - [ReminderType.daily]: evening nudge to write about the day just had — 21:00.
  /// - [ReminderType.onThisDay]: nostalgic look-back at past entries, best consumed
  ///   in the morning (like Timehop/Facebook Memories) rather than competing with
  ///   the evening writing nudge — 09:00.
  /// - [ReminderType.period]: advance notice before the predicted period — 09:00.
  factory ReminderObject.builtin(ReminderType type) {
    return ReminderObject(
      id: type.index + 1,
      type: type,
      enabled: false,
      hour: type == ReminderType.daily ? 21 : 9,
      minute: 0,
      daysAhead: type == ReminderType.period ? 2 : null,
    );
  }

  factory ReminderObject.fromJson(Map<String, dynamic> json) => _$ReminderObjectFromJson(json);
  Map<String, dynamic> toJson() => _$ReminderObjectToJson(this);
}
