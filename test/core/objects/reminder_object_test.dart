import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/types/reminder_type.dart';

void main() {
  group('ReminderObject', () {
    test('JSON round-trip preserves all fields', () {
      final reminder = ReminderObject(
        id: 12,
        type: ReminderType.custom,
        enabled: true,
        hour: 8,
        minute: 30,
        weekdays: [1, 3, 5],
        message: 'Review ideas',
        templateId: 7,
        tagIds: [2, 4],
      );

      final restored = ReminderObject.fromJson(reminder.toJson());

      expect(restored.id, 12);
      expect(restored.type, ReminderType.custom);
      expect(restored.enabled, true);
      expect(restored.hour, 8);
      expect(restored.minute, 30);
      expect(restored.weekdays, [1, 3, 5]);
      expect(restored.message, 'Review ideas');
      expect(restored.templateId, 7);
      expect(restored.tagIds, [2, 4]);
    });

    test('unknown reminder type falls back to custom', () {
      final json = {'id': 1, 'type': 'somethingNew', 'enabled': true};
      expect(ReminderObject.fromJson(json).type, ReminderType.custom);
    });

    test('isEveryDay is true when no weekdays selected', () {
      final reminder = ReminderObject(id: 1, type: ReminderType.daily);
      expect(reminder.isEveryDay, true);
      expect(reminder.scheduleSlots, [0]);
    });

    test('scheduleSlots returns sorted unique weekdays', () {
      final reminder = ReminderObject(id: 1, type: ReminderType.daily, weekdays: [5, 1, 1, 3]);
      expect(reminder.isEveryDay, false);
      expect(reminder.scheduleSlots, [1, 3, 5]);
    });

    test('normalizeWeekdays collapses both "all 7 selected" and "none selected" to every-day', () {
      expect(ReminderObject.normalizeWeekdays([]), []);
      expect(ReminderObject.normalizeWeekdays(ReminderObject.allWeekdays), []);
      expect(ReminderObject.normalizeWeekdays([1, 2, 3, 4, 5, 6, 7, 7]), []);
      expect(ReminderObject.normalizeWeekdays([5, 1, 1, 3]), [1, 3, 5]);
    });

    test('builtin factory uses type-based id and disabled default', () {
      final daily = ReminderObject.builtin(ReminderType.daily);
      final period = ReminderObject.builtin(ReminderType.period);

      expect(daily.type, ReminderType.daily);
      expect(daily.enabled, false);
      expect(daily.id, ReminderType.daily.index + 1);
      expect(period.daysAhead, 2);
    });
  });
}
