import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/services/calendar_days_generator.dart';
import 'package:storypad/core/services/days_count_in_month_service.dart';

void main() {
  group('CalendarDaysGenerator.generate', () {
    test('it generates correct number of days for previous, current, and next month', () {
      final result = CalendarDaysGenerator.generate(year: 2024, month: 2);

      final expectedCurrentMonthDayCount = DaysCountInMonthService.get(year: 2024, month: 2);
      const expectedTotalDays = 42;
      final expectedPreviousMonthDayCount = DateTime(2024, 2, 1).weekday == 7 ? 0 : DateTime(2024, 2, 1).weekday;
      final expectedNextMonthDayCount =
          expectedTotalDays - expectedCurrentMonthDayCount - expectedPreviousMonthDayCount;

      final previousMonthDays = result.where((d) => d.month == 1).length;
      final currentMonthDays = result.where((d) => d.month == 2).length;
      final nextMonthDays = result.where((d) => d.month == 3).length;

      expect(result.length, expectedTotalDays);
      expect(currentMonthDays, expectedCurrentMonthDayCount);
      expect(previousMonthDays, expectedPreviousMonthDayCount);
      expect(nextMonthDays, expectedNextMonthDayCount);
    });
  });

  group('CalendarDaysGenerator.generateCurrentMonthDays', () {
    test('it generates all days of the current month sequentially', () {
      final days = CalendarDaysGenerator.generateCurrentMonthDays(31, 2024, 5);

      expect(days.length, 31);
      expect(days.first, DateTime(2024, 5, 1));
      expect(days.last, DateTime(2024, 5, 31));
    });
  });
}
