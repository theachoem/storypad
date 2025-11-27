part of 'period_calendar_view.dart';

class _PeriodCalendarContent extends StatelessWidget {
  const _PeriodCalendarContent(this.viewModel);

  final PeriodCalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: NestedScrollView(
        controller: PrimaryScrollController.maybeOf(context),
        headerSliverBuilder: (context, _) {
          return [
            SliverPadding(
              padding: MediaQuery.paddingOf(context).copyWith(top: 0, bottom: 0),
              sliver: SliverToBoxAdapter(
                child: SpCalendar(
                  initialYear: viewModel.year,
                  initialMonth: viewModel.month,
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
                ),
              ),
            ),
          ];
        },
        body: SpStoryList(
          stories: viewModel.selectedEventStories,
          onChanged: (item) => viewModel.load(initialSelectedDate: viewModel.selectedEventDate),
          onDeleted: () => viewModel.load(initialSelectedDate: viewModel.selectedEventDate),
        ),
      ),
    );
  }
}
