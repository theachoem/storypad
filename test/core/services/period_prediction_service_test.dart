import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/period_prediction_service.dart';

void main() {
  group('PeriodPredictionService.predictNextPeriodStart', () {
    test('returns null without enough history', () {
      expect(PeriodPredictionService.predictNextPeriodStart([]), isNull);
      expect(
        PeriodPredictionService.predictNextPeriodStart([DateTime(2026, 1, 1)]),
        isNull,
      );
    });

    test('returns null with only one cycle (no gap to average)', () {
      // A single 3-day cycle -> one start only.
      final dates = [DateTime(2026, 1, 1), DateTime(2026, 1, 2), DateTime(2026, 1, 3)];
      expect(PeriodPredictionService.predictNextPeriodStart(dates), isNull);
    });

    test('predicts next start from two 28-day cycles', () {
      final dates = [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 2),
        DateTime(2026, 1, 3),
        DateTime(2026, 1, 29),
        DateTime(2026, 1, 30),
        DateTime(2026, 1, 31),
      ];
      final next = PeriodPredictionService.predictNextPeriodStart(
        dates,
        now: DateTime(2026, 2, 1),
      );
      // Last start Jan 29 + 28 days = Feb 26.
      expect(next, equals(DateTime(2026, 2, 26)));
    });

    test('rolls forward whole cycles when naive prediction is in the past', () {
      final dates = [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 29),
      ];
      // avg cycle = 28. Jan 29 + 28 = Feb 26, which is before "now" (Apr 1),
      // so it rolls forward: Feb 26 -> Mar 26 -> Apr 23.
      final next = PeriodPredictionService.predictNextPeriodStart(
        dates,
        now: DateTime(2026, 4, 1),
      );
      expect(next, equals(DateTime(2026, 4, 23)));
    });

    test('caps the averaging window to the most recent 6 months of starts', () {
      // An old irregular 60-day gap outside the 6-month window, followed by
      // three recent, regular 28-day cycles. If the old gap were included the
      // average would be pulled well above 28.
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 3, 2), // 60-day gap, older than 6 months before the last start.
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 29),
        DateTime(2026, 2, 26),
      ];
      final next = PeriodPredictionService.predictNextPeriodStart(
        dates,
        now: DateTime(2026, 3, 1),
      );
      // Only the recent 28-day cycles should count: Feb 26 + 28 = Mar 26.
      expect(next, equals(DateTime(2026, 3, 26)));
    });

    test('groups a cycle that spans a month boundary as a single start', () {
      // Month A: days 1-6. Month B: days 27-31 then day 2 (spans into next month).
      final dates = [
        for (final d in [1, 2, 3, 4, 5, 6]) DateTime(2026, 1, d),
        for (final d in [27, 28, 29, 30, 31]) DateTime(2026, 1, d),
        DateTime(2026, 2, 1),
        DateTime(2026, 2, 2),
      ];
      final next = PeriodPredictionService.predictNextPeriodStart(
        dates,
        now: DateTime(2026, 2, 3),
      );
      // Two cycle starts: Jan 1 and Jan 27 -> 26-day gap. Jan 27 + 26 = Feb 22.
      expect(next, equals(DateTime(2026, 2, 22)));
    });

    test('returns null when the most recent start is older than the history window', () {
      // Two real cycles, but the last one started 8 months before "now" —
      // way outside maxHistoryMonths (6). Nothing recent to extrapolate from.
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 29),
      ];
      final next = PeriodPredictionService.predictNextPeriodStart(
        dates,
        now: DateTime(2025, 9, 29),
      );
      expect(next, isNull);
    });

    test('still predicts when the most recent start is just inside the history window', () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 29),
      ];
      final next = PeriodPredictionService.predictNextPeriodStart(
        dates,
        now: DateTime(2025, 7, 20), // ~5.5 months after the last start.
      );
      expect(next, isNotNull);
    });

    test('ignores duplicate day entries', () {
      final dates = [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 29),
      ];
      final next = PeriodPredictionService.predictNextPeriodStart(
        dates,
        now: DateTime(2026, 2, 1),
      );
      expect(next, equals(DateTime(2026, 2, 26)));
    });
  });
}
