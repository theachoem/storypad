part of 'mood_calendar_view.dart';

class _CalendarStoriesContent extends StatelessWidget {
  const _CalendarStoriesContent(this.viewModel);

  final MoodCalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SpFadeIn.fromBottom(
        delay: Durations.medium1,
        child: FloatingActionButton(
          heroTag: null,
          tooltip: tr("button.new_story"),
          child: const Icon(SpIcons.newStory),
          onPressed: () => viewModel.goToNewPage(context),
        ),
      ),
      body: NestedScrollView(
        controller: PrimaryScrollController.maybeOf(context),
        headerSliverBuilder: (context, _) {
          return [
            SliverToBoxAdapter(
              child: SpScrollableChoiceChips<TagDbModel>(
                choices: viewModel.tags ?? [],
                storiesCount: (TagDbModel tag) =>
                    viewModel.tagSelected(tag) ? viewModel.currentFilterStoriesCount : null,
                toLabel: (TagDbModel tag) => tag.title,
                selected: (TagDbModel tag) => viewModel.tagSelected(tag),
                onToggle: (TagDbModel tag) => viewModel.selectTag(tag),
              ),
            ),
            SliverToBoxAdapter(
              child: SpCalendar(
                initialYear: viewModel.year,
                initialMonth: viewModel.month,
                onMonthChanged: viewModel.onMonthChanged,
                controller: viewModel.calendarController,
                cellBuilder: (context, date, isDisplayMonth) {
                  final feeling = isDisplayMonth ? viewModel.feelingMapByDay[date.day] : null;
                  return SpCalendarDateCell(
                    date: date,
                    selectedYear: viewModel.year,
                    selectedMonth: viewModel.month,
                    selectedDay: viewModel.selectedDay,
                    feeling: feeling,
                    isDisplayMonth: isDisplayMonth,
                    onTap: isDisplayMonth
                        ? () => viewModel.onDaySelected(
                            viewModel.year,
                            viewModel.month,
                            viewModel.selectedDay == date.day ? null : date.day,
                          )
                        : null,
                  );
                },
              ),
            ),
          ];
        },
        body: SpStoryList.withQuery(
          disableMultiEdit: true,
          filter: viewModel.searchFilter,
        ),
      ),
    );
  }
}
