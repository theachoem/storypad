part of '../discover_calendar_content.dart';

class _CalendarMonth extends StatelessWidget {
  final void Function(int year, int month, int selectedDay) onChanged;
  final int year;
  final int month;
  final int selectedDay;

  const _CalendarMonth({
    required this.onChanged,
    required this.year,
    required this.month,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final List<DateTime> visibleDays = CalendarDaysGenerator.generate(year: year, month: month);

    return AlignedGridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      crossAxisCount: DateTime.daysPerWeek,
      itemCount: visibleDays.length + DateTime.daysPerWeek,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        if (index < 7) return buildDayLabel(index, context);
        index = index - 7;

        DateTime date = visibleDays.elementAt(index);

        bool currentMonth = date.month == month;
        bool selected = "${date.day}-${date.month}-${date.year}" == "$selectedDay-$month-$year";

        Color? backgroundColor = selected ? ColorScheme.of(context).primary : null;
        Color? foregroundColor = currentMonth ? null : ColorScheme.of(context).onSurface.withValues(alpha: 0.5);

        if (selected) foregroundColor = ColorScheme.of(context).onPrimary;

        return Container(
          constraints: const BoxConstraints(minHeight: 72),
          alignment: Alignment.center,
          child: SpTapEffect(
            effects: [SpTapEffectType.scaleDown],
            onTap: !currentMonth ? null : () => onChanged(year, month, date.day),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
              ),
              child: Builder(
                builder: (context) {
                  return Text(
                    visibleDays.elementAtOrNull(index) != null
                        ? DateFormatHelper.d(visibleDays.elementAtOrNull(index)!, context.locale)
                        : 'N/A',
                    textAlign: TextAlign.center,
                    style: TextTheme.of(context).bodyLarge?.copyWith(color: foregroundColor),
                  );

                  // return SpAnimatedIcons.fadeScale(
                  //   showFirst: selected,
                  //   firstChild: FeelingObject.feelingsByKey.values.last.image64.image(width: 32),
                  //   secondChild: text,
                  // );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Padding buildDayLabel(int index, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        DateFormatHelper.E(DateTime(2000, 10, index + 1), context.locale),
        textAlign: TextAlign.center,
        style: TextTheme.of(context).titleSmall?.copyWith(
              color: index == 0 || index == 6 ? ColorScheme.of(context).error : null,
            ),
      ),
    );
  }
}
