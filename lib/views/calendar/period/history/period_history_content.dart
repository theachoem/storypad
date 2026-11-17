part of 'period_history_view.dart';

/// Looks like the stats page (`app/lib/views/stats/stats_content.dart`):
/// titled sections 24pt apart and [SpMetricChip]s three per row — but the
/// cycle list is built lazily since it grows with every logged period.
class _PeriodHistoryContent extends StatelessWidget {
  const _PeriodHistoryContent(this.viewModel);

  final PeriodHistoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('page.period_history.title'))),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cycles = viewModel.cycles;
    if (cycles == null) return const Center(child: CircularProgressIndicator.adaptive());

    // Flat and lazy: overview first, then each year's title followed by its
    // cycles. History grows with every logged period (unlike the capped stats
    // lists), so only visible rows get built and painted.
    final List<Object> entries = [
      if (viewModel.isDemo) _HeaderEntry.demoNotice,
      _HeaderEntry.overview,
      for (final year in cycles.map((c) => c.start.year).toSet()) ...[
        year,
        ...cycles.where((c) => c.start.year == year),
      ],
    ];

    // One fade for the whole list: per-item fades (as stats does) would replay
    // whenever a lazily built row scrolls back into view.
    return SpFadeIn.fromBottom(
      delay: const Duration(milliseconds: 50),
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 16.0,
          bottom: 48.0 + MediaQuery.paddingOf(context).bottom,
          left: MediaQuery.paddingOf(context).left + 16.0,
          right: MediaQuery.paddingOf(context).right + 16.0,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (entry == _HeaderEntry.demoNotice) return _buildDemoNotice(context);

          final Widget child = switch (entry) {
            final PeriodCycleObject cycle => _buildCycleRow(context, cycle),
            // Same 24pt section gap and 8pt title→content gap as stats.
            final int year => Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SpSectionTitle(title: year.toString(), padding: EdgeInsets.zero),
            ),
            _ => _buildSection(
              context,
              title: tr('page.stats.section.overview'),
              paddingBottom: 4.0,
              child: _buildOverview(context),
            ),
          };

          // Sample data reads as a preview: dimmed and not tappable.
          if (!viewModel.isDemo) return child;
          return IgnorePointer(child: Opacity(opacity: 0.4, child: child));
        },
      ),
    );
  }

  /// Shown above the dimmed sample history when nothing is logged yet.
  Widget _buildDemoNotice(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final textTheme = TextTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.readOnly.surface3,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8.0,
        children: [
          Row(
            spacing: 8.0,
            children: [
              Icon(SpIcons.waterDrop, size: 20.0, color: colorScheme.error),
              Expanded(child: Text(tr('page.period_history.empty'), style: textTheme.titleMedium)),
            ],
          ),
          Text(
            tr('page.period_history.example_note'),
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4.0),
          SpFilledButton(
            onPressed: () => viewModel.openCalendar(context),
            child: Text(tr('button.view_calendar')),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
    double paddingBottom = 0.0,
  }) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 8.0,
      children: [
        SpSectionTitle(title: title, padding: EdgeInsets.zero),
        child,
        if (paddingBottom > 0) SizedBox(height: paddingBottom),
      ],
    );
  }

  Widget _buildOverview(BuildContext context) {
    final predicted = viewModel.predictedNextStart;
    final metrics = [
      (
        icon: SpIcons.refresh,
        value: _formatDays(viewModel.averageCycleLength),
        label: tr('page.period_history.average_cycle'),
      ),
      (
        icon: SpIcons.waterDrop,
        value: _formatDays(viewModel.averagePeriodLength),
        label: tr('page.period_history.average_period'),
      ),
      (
        icon: SpIcons.calendar,
        value: predicted != null ? DateFormatHelper.MMMd(predicted, context.locale) : '-',
        label: tr('page.period_history.next_period'),
      ),
    ];

    return Column(
      crossAxisAlignment: .start,
      spacing: 8.0,
      children: [
        Row(
          spacing: 8.0,
          children: [
            for (final metric in metrics)
              Expanded(
                child: SpMetricChip(icon: metric.icon, value: metric.value, label: metric.label),
              ),
          ],
        ),
        Text(
          tr(
            'page.period_history.averages_note',
            namedArgs: {'SP_MONTHS': PeriodPredictionService.maxHistoryMonths.toString()},
          ),
          style: TextTheme.of(context).bodySmall?.copyWith(
            color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  /// Date range over its period and cycle lengths. No leading icon or bar —
  /// the same icon on every row adds nothing, and the lengths say it all.
  Widget _buildCycleRow(BuildContext context, PeriodCycleObject cycle) {
    final colorScheme = ColorScheme.of(context);
    final textTheme = TextTheme.of(context);

    final currentDay = viewModel.currentCycleDay(cycle);

    final details = [
      tr('page.period_history.period_length', namedArgs: {'SP_DAYS': plural('plural.day', cycle.periodLength)}),
      if (cycle.cycleLength != null)
        tr('page.period_history.cycle_length', namedArgs: {'SP_DAYS': plural('plural.day', cycle.cycleLength!)})
      else if (currentDay != null)
        tr('page.period_history.cycle_day', namedArgs: {'SP_DAY': currentDay.toString()}),
    ];

    return SpTapEffect(
      onTap: () => viewModel.openCycle(context, cycle),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              _formatRange(context, cycle),
              maxLines: 1,
              overflow: .ellipsis,
              style: textTheme.titleMedium,
            ),
            Text(
              details.join(' · '),
              maxLines: 1,
              overflow: .ellipsis,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRange(BuildContext context, PeriodCycleObject cycle) {
    final start = DateFormatHelper.MMMd(cycle.start, context.locale);
    if (cycle.periodLength == 1) return start;

    // A period crossing New Year sits under the start year's section, so the
    // end carries its own year to stay unambiguous.
    final end = cycle.end.year == cycle.start.year
        ? DateFormatHelper.MMMd(cycle.end, context.locale)
        : DateFormatHelper.yMMMd(cycle.end, context.locale);
    return '$start – $end';
  }

  String _formatDays(double? days) => days != null ? plural('plural.day', days.round()) : '-';
}

/// Non-cycle rows in the lazy history list.
enum _HeaderEntry { demoNotice, overview }
