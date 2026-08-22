part of 'period_calendar_view.dart';

class _PeriodCalendarContent extends StatelessWidget {
  const _PeriodCalendarContent(this.viewModel);

  final PeriodCalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        automaticallyImplyActions: false,
        toolbarHeight: 12,
      ),
      floatingActionButtonLocation: SpFabLocation.endFloat(context),
      floatingActionButton: Visibility(
        visible: viewModel.selectedEvent != null,
        child: SpFadeIn.fromBottom(
          delay: Durations.medium1,
          child: FloatingActionButton(
            heroTag: null,
            tooltip: tr("button.new_story"),
            child: const Icon(SpIcons.newStory),
            onPressed: () => viewModel.goToNewPage(context),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 700) {
            return buildBigScreenView(context);
          } else {
            return buildSmallScreenView(context);
          }
        },
      ),
    );
  }

  Widget buildBigScreenView(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.paddingOf(context).left + 16.0,
        right: MediaQuery.paddingOf(context).right,
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: MediaQuery.paddingOf(context).copyWith(left: 0, right: 0)),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: buildCalendar(context, showBottomBorder: false, scrollable: true),
              ),
            ),
            Flexible(
              child: Stack(
                children: [
                  buildStoryList(context),
                  buildReminderTile(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSmallScreenView(BuildContext context) {
    return NestedScrollView(
      controller: PrimaryScrollController.maybeOf(context),
      headerSliverBuilder: (context, _) {
        return [
          SliverPadding(
            padding: MediaQuery.paddingOf(context).copyWith(top: 0, bottom: 0),
            sliver: SliverToBoxAdapter(
              child: buildCalendar(context, showBottomBorder: true),
            ),
          ),
        ];
      },
      body: Stack(
        children: [
          buildStoryList(context),
          buildReminderTile(context),
        ],
      ),
    );
  }

  /// Compact entry point to the built-in period reminder — full editing
  /// (time, enable/disable) happens in [SpEditReminderSheet], same as the
  /// reminders page. Scoped to `periodReminder` via `context.select` so this
  /// tile only rebuilds when that specific reminder changes.
  Widget buildReminderTile(BuildContext context) {
    final reminder = context.select((DevicePreferencesProvider provider) => provider.periodReminder);
    final enabled = reminder?.enabled ?? false;

    void openSheet() =>
        SpEditReminderSheet(reminder: reminder ?? ReminderObject.builtin(ReminderType.period)).show(context: context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16.0, right: 12.0),
        tileColor: Colors.transparent,
        leading: const Icon(SpIcons.alarm),
        title: Text(ReminderType.period.title),
        subtitle: Text(
          enabled && reminder != null
              ? tr(
                  'reminder.summary.around_time',
                  namedArgs: {'S_TIME': MaterialLocalizations.of(context).formatTimeOfDay(reminder.timeOfDay)},
                )
              : ReminderType.period.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch.adaptive(value: enabled, onChanged: (_) => openSheet()),
        onTap: openSheet,
      ),
    );
  }

  Widget buildCalendar(
    BuildContext context, {
    required bool showBottomBorder,
    bool scrollable = false,
  }) {
    final firstDayOfWeek = context.select(
      (DevicePreferencesProvider provider) => provider.preferences.firstDayOfWeek,
    );

    Widget child = SpCalendar(
      showBottomBorder: showBottomBorder,
      initialYear: viewModel.year,
      initialMonth: viewModel.month,
      firstDayOfWeek: firstDayOfWeek,
      onMonthChanged: viewModel.onMonthChanged,
      controller: viewModel.calendarController,
      cellBuilder: (context, date, isDisplayMonth) {
        return SpCalendarPeriodDateCell(
          date: date,
          isDisplayMonth: isDisplayMonth,
          isLastMonthPeriodDate: viewModel.isLastMonthPeriodDate(date),
          isPeriodDate: viewModel.isPeriodDate(date),
          selected: viewModel.isDateSelected(date),
          onTap: isDisplayMonth ? () => viewModel.toggleDate(context, date) : null,
        );
      },
    );

    if (scrollable) {
      return SingleChildScrollView(child: child);
    } else {
      return child;
    }
  }

  // Matches the two-line ListTile in buildReminderTile — the story list needs
  // this much top padding so its content clears the tile floating over it.
  static const double _reminderTileHeight = 72.0;

  Widget buildStoryList(BuildContext context) {
    if (viewModel.selectedEventStories?.items == null || viewModel.selectedEventStories?.items.isEmpty == true) {
      return Padding(
        padding: const EdgeInsets.all(16.0).copyWith(top: 16.0 + _reminderTileHeight),
        child: Text(
          tr('general.no_story_yet'),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: .center,
        ),
      );
    }

    return SpStoryList(
      paddingTop: _reminderTileHeight,
      stories: viewModel.selectedEventStories,
      onChanged: (item) => viewModel.load(initialSelectedDate: viewModel.selectedEventDate),
      onDeleted: () => viewModel.load(initialSelectedDate: viewModel.selectedEventDate),
    );
  }
}
