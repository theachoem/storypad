part of '../sp_story_tile_list_item.dart';

/// Minimal stats block embedded at each month header on the timeline.
///
/// The low-stakes "momentum nudge": leads with monthly coverage (active days
/// out of the month) and a compact muted line of pluralized counts. Tapping
/// opens the dedicated stats screen.
///
/// All numbers come from [stats]; the model owns formatting/localization so
/// this widget just renders and joins the labels.
class _StoryMonthRecap extends StatelessWidget {
  const _StoryMonthRecap({
    required this.story,
    required this.stats,
  });

  final StoryDbModel story;
  final MonthRecapStatsObject stats;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);

    return SpTapEffect(
      onTap: () {},
      child: ListTile(
        leading: Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.bootstrap.warning.color, width: 1.0),
          ),
          child: Icon(SpIcons.star, size: 20.0, color: colorScheme.bootstrap.warning.color),
        ),
        title: Text(stats.titleLabel(context.locale)),
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: stats.activeDaysLabel),
              TextSpan(
                text: " · ${stats.labels.join(" · ")}",
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
