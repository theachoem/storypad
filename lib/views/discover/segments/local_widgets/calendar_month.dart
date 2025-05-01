part of '../discover_calendar_content.dart';

class _CalendarMonth extends StatelessWidget {
  const _CalendarMonth({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.feelingMapByDay,
    required this.onChanged,
  });

  final int month;
  final int year;
  final int selectedDay;
  final Map<int, String?> feelingMapByDay;
  final void Function(int year, int month, int selectedDay) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8.0),
        Padding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
          child: _CalendarMonthHeader(
            onChanged: onChanged,
            year: year,
            month: month,
            selectedDay: selectedDay,
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8.0),
        Padding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
          child: Column(
            children: [
              buildDaysHeader(context),
              buildCalendar(context),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget buildDaysHeader(BuildContext context) {
    return Row(
      children: List.generate(DateTime.daysPerWeek, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              DateFormatHelper.E(DateTime(2000, 10, index + 1), context.locale),
              textAlign: TextAlign.center,
              style: TextTheme.of(context).titleSmall?.copyWith(
                    color: index == 0 || index == 6 ? ColorScheme.of(context).error : null,
                  ),
            ),
          ),
        );
      }),
    );
  }

  Widget buildCalendar(BuildContext context) {
    final List<DateTime> visibleDays = CalendarDaysGenerator.generate(year: year, month: month);
    return AlignedGridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: visibleDays.length,
      crossAxisCount: DateTime.daysPerWeek,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final date = visibleDays.elementAt(index);

        return _CalendarDate(
          feeling: date.month == month ? feelingMapByDay[date.day] : null,
          onChanged: onChanged,
          date: date,
          selectedYear: year,
          selectedMonth: month,
          selectedDay: selectedDay,
        );
      },
    );
  }
}
