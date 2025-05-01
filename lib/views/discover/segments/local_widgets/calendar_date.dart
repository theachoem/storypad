part of '../discover_calendar_content.dart';

class _CalendarDate extends StatelessWidget {
  const _CalendarDate({
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    required this.date,
    required this.feeling,
    required this.onChanged,
  });

  final int selectedYear;
  final int selectedMonth;
  final int? selectedDay;

  final DateTime date;
  final String? feeling;

  final void Function(int year, int month, int selectedDay) onChanged;

  @override
  Widget build(BuildContext context) {
    bool currentMonth = date.month == selectedMonth;
    bool selected = "${date.day}-${date.month}-${date.year}" == "$selectedDay-$selectedMonth-$selectedYear";

    DateTime now = DateTime.now();
    bool isToday = date == DateTime(now.year, now.month, now.day);

    Widget child = buildDateContent(
      context: context,
      currentMonth: currentMonth,
      date: date,
      selected: selected,
    );

    return SpTapEffect(
      effects: [SpTapEffectType.scaleDown],
      onTap: !currentMonth ? null : () => onChanged(selectedYear, selectedMonth, date.day),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Center(
              child: AnimatedContainer(
                width: 38,
                height: 38,
                duration: Durations.medium1,
                curve: Curves.ease,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: ColorScheme.of(context).primary, width: selected ? 2 : 1) : null,
                ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 56),
            child: AnimatedSwitcher(
              duration: Durations.medium1,
              switchInCurve: Curves.ease,
              switchOutCurve: Curves.ease,
              child: child,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDateContent({
    required BuildContext context,
    required bool currentMonth,
    required DateTime date,
    required bool selected,
  }) {
    bool hasFeeling = currentMonth && feeling != null && FeelingObject.feelingsByKey[feeling] != null;
    bool hasStoriesButNoFeeling = currentMonth && feeling != null && FeelingObject.feelingsByKey[feeling] == null;

    Color? backgroundColor = selected ? ColorScheme.of(context).primary : null;
    Color foregroundColor = selected ? ColorScheme.of(context).onPrimary : ColorScheme.of(context).onSurface;
    if (!currentMonth) foregroundColor = foregroundColor.withValues(alpha: 0.5);

    if (hasFeeling) {
      return AnimatedContainer(
        key: const ValueKey('has-stories-has-feeling'),
        duration: Durations.medium1,
        curve: Curves.ease,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor?.withValues(alpha: 0.1),
        ),
        alignment: Alignment.center,
        child: FeelingObject.feelingsByKey[feeling]?.image64.image(width: 26),
      );
    } else if (hasStoriesButNoFeeling) {
      return AnimatedContainer(
        key: const ValueKey('has-stories-no-feeling'),
        duration: Durations.medium1,
        curve: Curves.ease,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
        alignment: Alignment.center,
        child: Icon(SpIcons.check, color: foregroundColor),
      );
    } else {
      return AnimatedContainer(
        key: const ValueKey('no-stories'),
        duration: Durations.medium1,
        curve: Curves.ease,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
        alignment: Alignment.center,
        child: Text(
          DateFormatHelper.d(date, context.locale),
          textAlign: TextAlign.center,
          style: TextTheme.of(context).bodyLarge?.copyWith(color: foregroundColor),
        ),
      );
    }
  }
}
