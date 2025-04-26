import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/days_count_in_month_service.dart';

void main() {
  group('DaysCountInMonthService.get', () {
    test('it returns correct day count for non-leap year February', () {
      expect(DaysCountInMonthService.get(year: 2023, month: DateTime.february), 28);
    });

    test('it returns correct day count for leap year February', () {
      expect(DaysCountInMonthService.get(year: 2024, month: DateTime.february), 29);
    });

    test('it returns correct day counts for all months in a common year', () {
      final expectedDays = {
        DateTime.january: 31,
        DateTime.february: 28,
        DateTime.march: 31,
        DateTime.april: 30,
        DateTime.may: 31,
        DateTime.june: 30,
        DateTime.july: 31,
        DateTime.august: 31,
        DateTime.september: 30,
        DateTime.october: 31,
        DateTime.november: 30,
        DateTime.december: 31,
      };

      expectedDays.forEach((month, days) {
        expect(
          DaysCountInMonthService.get(year: 2023, month: month),
          days,
          reason: 'Month: $month',
        );
      });
    });

    test('it returns correct day counts for all months in a leap year', () {
      final expectedDaysLeapYear = {
        DateTime.january: 31,
        DateTime.february: 29, // Leap year Feb
        DateTime.march: 31,
        DateTime.april: 30,
        DateTime.may: 31,
        DateTime.june: 30,
        DateTime.july: 31,
        DateTime.august: 31,
        DateTime.september: 30,
        DateTime.october: 31,
        DateTime.november: 30,
        DateTime.december: 31,
      };

      expectedDaysLeapYear.forEach((month, days) {
        expect(
          DaysCountInMonthService.get(year: 2024, month: month),
          days,
          reason: 'Month: $month',
        );
      });
    });
  });
}
