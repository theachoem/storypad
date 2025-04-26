part of '../discover_calendar_content.dart';

class _CalendarMonthWithHeader extends StatelessWidget {
  const _CalendarMonthWithHeader({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.onChanged,
  });

  final int month;
  final int year;
  final int selectedDay;
  final void Function(int year, int month, int selectedDay) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        const Divider(height: 1),
        _CalendarMonthHeader(
          onChanged: onChanged,
          year: year,
          month: month,
          selectedDay: selectedDay,
        ),
        const Divider(height: 1),
        const SizedBox(height: 8.0),
        _CalendarMonth(
          onChanged: onChanged,
          year: year,
          month: month,
          selectedDay: selectedDay,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
