part of 'story_header.dart';

class _StoryHeaderDateSelector extends StatelessWidget {
  const _StoryHeaderDateSelector({
    required this.story,
    required this.readOnly,
    required this.onChangeDate,
  });

  final StoryDbModel story;
  final bool readOnly;
  final Future<void> Function(DateTime)? onChangeDate;

  Future<void> changeDate(BuildContext context) async {
    DateTime? date = await DatePickerService(context: context, currentDate: story.displayPathDate).show();
    if (date != null) {
      onChangeDate?.call(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      InkWell(
        onTap: readOnly || onChangeDate == null ? null : () => changeDate(context),
        borderRadius: BorderRadius.circular(4.0),
        child: Row(
          children: [
            buildDay(context),
            const SizedBox(width: 4.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildDaySuffix(context),
                buildMonthYear(context),
              ],
            ),
            if (!readOnly) ...[
              const SizedBox(width: 4.0),
              const Icon(SpIcons.dropDown),
            ]
          ],
        ),
      ),
    ]);
  }

  Widget buildMonthYear(BuildContext context) {
    return Text(
      DateFormatHelper.yMMMM(story.displayPathDate, context.locale),
      style: TextTheme.of(context).labelMedium,
    );
  }

  Widget buildDaySuffix(BuildContext context) {
    return Text(
      SpDateBlockEmbed.getDayOfMonthSuffix(story.day).toLowerCase(),
      style: TextTheme.of(context).labelSmall,
    );
  }

  Widget buildDay(BuildContext context) {
    Color? color;

    if (story.preferences.colorSeedValue != null) {
      color = ColorScheme.of(context).primary;
    } else {
      color = ColorFromDayService(context: context).get(story.displayPathDate.weekday);
    }

    return Text(
      story.day.toString().padLeft(2, '0'),
      style: TextTheme.of(context).headlineLarge?.copyWith(color: color),
    );
  }
}
