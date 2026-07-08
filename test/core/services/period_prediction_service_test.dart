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
