import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/on_this_day_prediction_service.dart';

void main() {
  group('OnThisDayPredictionService.findUpcomingMemoryDates', () {
    test('returns empty when nothing matches in the horizon', () {
      final result = OnThisDayPredictionService.findUpcomingMemoryDates(
        from: DateTime(2026, 1, 1),
        hasMemoriesOn: (month, day) => false,
      );
      expect(result, isEmpty);
    });

    test('includes only dates that have memories, in order', () {
      // Memories exist on Jan 3 and Jan 10.
      final result = OnThisDayPredictionService.findUpcomingMemoryDates(
        from: DateTime(2026, 1, 1),
        horizonDays: 14,
        hasMemoriesOn: (month, day) => month == 1 && (day == 3 || day == 10),
      );
      expect(result, [DateTime(2026, 1, 3), DateTime(2026, 1, 10)]);
    });

    test('includes today (offset 0) when it matches', () {
      final result = OnThisDayPredictionService.findUpcomingMemoryDates(
        from: DateTime(2026, 3, 5),
        horizonDays: 5,
        hasMemoriesOn: (month, day) => month == 3 && day == 5,
      );
      expect(result, [DateTime(2026, 3, 5)]);
    });

    test('stops scanning once maxResults is reached', () {
      final result = OnThisDayPredictionService.findUpcomingMemoryDates(
        from: DateTime(2026, 1, 1),
        horizonDays: 30,
        maxResults: 2,
        hasMemoriesOn: (month, day) => true, // every day matches
      );
      expect(result, hasLength(2));
      expect(result, [DateTime(2026, 1, 1), DateTime(2026, 1, 2)]);
    });

    test('never looks beyond the horizon', () {
      final checkedOffsets = <int>[];
      OnThisDayPredictionService.findUpcomingMemoryDates(
        from: DateTime(2026, 1, 1),
        horizonDays: 3,
        hasMemoriesOn: (month, day) {
          checkedOffsets.add(day);
          return false;
        },
      );
      // Offsets 0..3 inclusive -> days 1,2,3,4.
      expect(checkedOffsets, [1, 2, 3, 4]);
    });
  });
}
