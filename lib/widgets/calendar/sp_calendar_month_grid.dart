part of 'sp_calendar.dart';

/// A single month calendar grid widget.
///
/// Displays a grid of dates for a specific month, including overflow dates
/// from previous and next months to fill the grid.
class _SpCalendarMonthGrid extends StatelessWidget {
  const _SpCalendarMonthGrid({
    required this.year,
    required this.month,
    required this.currentYear,
    required this.currentMonth,
    required this.selectedDay,
    required this.feelingMapByDay,
    required this.onDayTapped,
  });

  final int year;
  final int month;
  final int currentYear;
  final int currentMonth;
  final int? selectedDay;
  final Map<int, String?> feelingMapByDay;
  final void Function(int day) onDayTapped;

  @override
  Widget build(BuildContext context) {
    final visibleDays = CalendarDaysGenerator.generate(year: year, month: month);
    const crossAxisCount = DateTime.daysPerWeek;
    final itemCount = visibleDays.length;

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final date = visibleDays[index];
        final isCurrentMonth = date.month == month;
        final feeling = isCurrentMonth ? feelingMapByDay[date.day] : null;

        return _SpCalendarDateCell(
          date: date,
          selectedYear: currentYear,
          selectedMonth: currentMonth,
          selectedDay: selectedDay,
          feeling: feeling,
          isCurrentMonth: isCurrentMonth,
          onTap: isCurrentMonth ? () => onDayTapped(date.day) : null,
        );
      },
    );
  }
}
