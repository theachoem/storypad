import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/notifications/reminder_notification_copy_service.dart';

void main() {
  group('ReminderNotificationCopyService content pools', () {
    // test/flutter_test_config.dart mocks SharedPreferences with no 'locale'
    // key set, so _useEnglishVariants() defaults to English here — exercising
    // the variant pools rather than the single tr() fallback.
    Future<Set<(String, String)>> collect(Future<(String, String)> Function() pick, {int attempts = 200}) async {
      final seen = <(String, String)>{};
      for (var i = 0; i < attempts; i++) {
        seen.add(await pick());
      }
      return seen;
    }

    test('dailyCopy stays within a bounded, non-duplicated pool (<=20)', () async {
      final seen = await collect(ReminderNotificationCopyService.dailyCopy);
      expect(seen.length, lessThanOrEqualTo(20));
      final titles = seen.map((e) => e.$1).toSet();
      expect(titles.length, seen.length, reason: 'no two pairs should share a title');
    });

    test('onThisDayCopy stays within a bounded, non-duplicated pool (<=20)', () async {
      final seen = await collect(ReminderNotificationCopyService.onThisDayCopy);
      expect(seen.length, lessThanOrEqualTo(20));
      final titles = seen.map((e) => e.$1).toSet();
      expect(titles.length, seen.length, reason: 'no two pairs should share a title');
    });

    test('periodCopy stays within a bounded, non-duplicated pool (<=20)', () async {
      final seen = await collect(ReminderNotificationCopyService.periodCopy);
      expect(seen.length, lessThanOrEqualTo(20));
      final titles = seen.map((e) => e.$1).toSet();
      expect(titles.length, seen.length, reason: 'no two pairs should share a title');
    });

    test('every picked pair has non-empty title and body', () async {
      for (final pick in [
        ReminderNotificationCopyService.dailyCopy,
        ReminderNotificationCopyService.onThisDayCopy,
        ReminderNotificationCopyService.periodCopy,
      ]) {
        final (title, body) = await pick();
        expect(title.trim(), isNotEmpty);
        expect(body.trim(), isNotEmpty);
      }
    });
  });
}
