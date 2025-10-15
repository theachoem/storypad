part of 'sp_calendar.dart';

/// A single month calendar grid widget.
///
/// Displays a grid of dates for a specific month, including overflow dates
/// from previous and next months to fill the grid.
class _SpCalendarMonthGrid extends StatelessWidget {
  const _SpCalendarMonthGrid({
    required this.year,
    required this.month,
    required this.cellBuilder,
  });

  final int year;
  final int month;
  final Widget Function(BuildContext context, DateTime date, bool isCurrentMonth) cellBuilder;

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
        mainAxisSpacing: 0.0,
        crossAxisSpacing: 0.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final date = visibleDays[index];
        final isCurrentMonth = date.month == month;
        return cellBuilder(context, date, isCurrentMonth);
      },
    );
  }
}
