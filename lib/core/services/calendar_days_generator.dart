import 'package:storypad/core/services/days_count_in_month_service.dart';

class CalendarDaysGenerator {
  static const int totalCells = DateTime.daysPerWeek * totalRows;
  static const int totalRows = 6;

  // This class generates 42 visible days for a calendar grid (7 columns × 6 rows).
  // - The current month's days (28–31 days) are placed based on the given year and month.
  // - Empty slots before the 1st day are filled with the last few days from the previous month.
  // - Remaining slots after the current month are filled with the first few days of the next month.
  //
  // This ensures the calendar always shows 42 cells regardless of the month's length.
  static List<DateTime> generate({
    required int year,
    required int month,
  }) {
    int visiblePreviousMonthDayCount = DateTime(year, month, 1).weekday == 7 ? 0 : DateTime(year, month, 1).weekday;
    int visibleCurrentMonthDayCount = DaysCountInMonthService.get(year: year, month: month);
    int visibleNextMonthDayCount = totalCells - visibleCurrentMonthDayCount - visiblePreviousMonthDayCount;

    List<DateTime> visiblePreviousMonthDays = generatePreviousMonthDays(visiblePreviousMonthDayCount, month, year);
    List<DateTime> visibleCurrentMonthDays = generateCurrentMonthDays(visibleCurrentMonthDayCount, year, month);
    List<DateTime> visibleNextMonthDays = generateNextMonthDays(visibleNextMonthDayCount, month, year);

    return [
      ...visiblePreviousMonthDays,
      ...visibleCurrentMonthDays,
      ...visibleNextMonthDays,
    ];
  }

  static List<DateTime> generatePreviousMonthDays(int dayCount, int month, int year) {
    return List.generate(dayCount, (index) {
      int yearForThisMonth = month - 1 == 0 ? year - 1 : year;
      int previousMonth = month - 1 == 0 ? 12 : month - 1;

      int dayCount = DaysCountInMonthService.get(year: yearForThisMonth, month: previousMonth);
      int day = dayCount - dayCount + (index + 1);

      return DateTime(yearForThisMonth, previousMonth, day);
    });
  }

  static List<DateTime> generateCurrentMonthDays(int dayCount, int year, int month) {
    return List.generate(dayCount, (index) {
      return DateTime(year, month, index + 1);
    });
  }

  static List<DateTime> generateNextMonthDays(int dayCount, int month, int year) {
    return List.generate(dayCount, (index) {
      int yearForThisMonth = month + 1 == 13 ? year + 1 : year;
      int nextMonth = month + 1 == 13 ? 1 : month + 1;
      int day = index + 1;

      return DateTime(yearForThisMonth, nextMonth, day);
    });
  }
}
