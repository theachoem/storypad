import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/services/notifications/reminder_navigation_service.dart';
import 'package:storypad/core/types/reminder_type.dart';

void main() {
  group('ReminderNavigationService.copyFor — custom reminders', () {
    test('uses the user message as the title, with a fixed generic body', () async {
      final reminder = ReminderObject(id: 10, type: ReminderType.custom, message: 'Check ideas tag');
      final (title, body) = await ReminderNavigationService.copyFor(reminder);

      expect(title, 'Check ideas tag');
      expect(body, isNotEmpty);
    });

    test('trims surrounding whitespace from the message', () async {
      final reminder = ReminderObject(id: 12, type: ReminderType.custom, message: '  Write weekly plan  ');
      final (title, _) = await ReminderNavigationService.copyFor(reminder);

      expect(title, 'Write weekly plan');
    });

    test('throws if message is null — EditCustomReminderViewModel must never save one without it', () async {
      final reminder = ReminderObject(id: 13, type: ReminderType.custom, message: null);
      await expectLater(ReminderNavigationService.copyFor(reminder), throwsA(isA<TypeError>()));
    });
  });
}
