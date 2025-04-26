part of '../discover_calendar_content.dart';

class _CalendarMonthHeader extends StatelessWidget {
  const _CalendarMonthHeader({
    required this.onChanged,
    required this.year,
    required this.month,
    required this.selectedDay,
  });

  final void Function(int year, int month, int selectedDay) onChanged;
  final int month;
  final int year;
  final int selectedDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(SpIcons.keyboardLeft),
          onPressed: () {
            onChanged(
              month - 1 == 0 ? year - 1 : year,
              month - 1 == 0 ? 12 : month - 1,
              selectedDay,
            );
          },
        ),
        SpTapEffect(
          onTap: () async {
            final result = await MonthPickerService(context: context, month: month, year: year).showPicker();
            if (result != null) onChanged(result.year, result.month, selectedDay);
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              DateFormatHelper.yMMMM(DateTime(year, month, 1), context.locale),
              key: ValueKey("$month-$year"),
              style: TextTheme.of(context).titleMedium,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(SpIcons.keyboardRight),
          onPressed: () {
            onChanged(
              month + 1 == 13 ? year + 1 : year,
              month + 1 == 13 ? 1 : month + 1,
              selectedDay,
            );
          },
        ),
      ],
    );
  }
}
