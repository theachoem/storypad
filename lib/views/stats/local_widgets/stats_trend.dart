part of '../stats_view.dart';

/// Entries-over-time as 12 monthly bars for the selected year, each bar's height
/// proportional to the busiest month. Only shown on the year tab — month tabs
/// omit it entirely.
///
/// ```
/// 3        5
/// ▁  ▂  █  ▅  ▂  ▁  _  _  ▃  ▁  _  _
/// J  F  M  A  M  J  J  A  S  O  N  D
/// ```
class _StatsTrend extends StatelessWidget {
  const _StatsTrend({
    required this.stats,
    required this.range,
  });

  static const double _barAreaHeight = 96.0;

  final StoryStatsObject stats;
  final StatsRange range;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);
    final TextTheme textTheme = TextTheme.of(context);

    final List<int> totals = List.filled(12, 0);
    stats.dailyCounts.forEach((day, count) {
      if (day.year == range.anchor.year) totals[day.month - 1] += count;
    });
    final int maxCount = totals.fold(
      0,
      (max, count) => count > max ? count : max,
    );

    final List<({String label, int count})> bars = [
      for (int month = 1; month <= 12; month++)
        (
          label: DateFormatHelper.MMM(
            DateTime(range.anchor.year, month),
            context.locale,
          ),
          count: totals[month - 1],
        ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600.0),
        child: Row(
          crossAxisAlignment: .end,
          spacing: 4.0,
          children: [
            for (final bar in bars)
              Expanded(
                child: Column(
                  mainAxisSize: .min,
                  spacing: 4.0,
                  children: [
                    Text(
                      bar.count > 0 ? '${bar.count}' : '',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(
                      height: _barAreaHeight,
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: maxCount == 0 ? 0.02 : (bar.count / maxCount).clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bar.count > 0
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      bar.label,
                      maxLines: 1,
                      overflow: .clip,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
