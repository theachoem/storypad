part of 'mood_calendar_view.dart';

class _CalendarStoriesContent extends StatelessWidget {
  const _CalendarStoriesContent(this.viewModel);

  final MoodCalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        automaticallyImplyActions: false,
        toolbarHeight: 12,
        bottom: viewModel.tags?.isNotEmpty == true
            ? PreferredSize(
                preferredSize: const Size.fromHeight(34.0 + 12.0 + 1.0),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SpScrollableChoiceChips<TagDbModel>(
                      choices: viewModel.tags ?? [],
                      storiesCount: (TagDbModel tag) =>
                          viewModel.tagSelected(tag) ? viewModel.currentFilterStoriesCount : null,
                      toLabel: (TagDbModel tag) => tag.title,
                      selected: (TagDbModel tag) => viewModel.tagSelected(tag),
                      onToggle: (TagDbModel tag) => viewModel.selectTag(tag),
                    ),
                    const SizedBox(height: 12.0),
                    const Divider(height: 1),
                  ],
                ),
              )
            : const PreferredSize(
                preferredSize: Size.fromHeight(1.0),
                child: Divider(height: 1),
              ),
      ),
      floatingActionButton: SpFadeIn.fromBottom(
        delay: Durations.medium1,
        child: FloatingActionButton(
          heroTag: null,
          tooltip: tr("button.new_story"),
          child: const Icon(SpIcons.newStory),
          onPressed: () => viewModel.goToNewPage(context),
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
    return Row(
      children: [
        Flexible(child: buildCalendar(showBottomBorder: false)),
        const VerticalDivider(),
        Flexible(child: buildStoryList()),
      ],
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
              child: buildCalendar(showBottomBorder: true),
            ),
          ),
        ];
      },
      body: buildStoryList(),
    );
  }

  Widget buildStoryList() {
    // Get the number of days in the current month
    // DateTime(year, month, 0) returns the last day of the previous month
    // So DateTime(year, month + 1, 0) gives us the last day of the current month
    // For example: DateTime(2025, 1, 0) = Dec 31, 2024 (last day of Dec)
    //              DateTime(2025, 2, 0) = Jan 31, 2025 (last day of Jan)
    final daysInMonth = DateTime(viewModel.year, viewModel.month + 1, 0).day;

    return PageView.builder(
      onPageChanged: (index) {
        // Index 0 = show all (selectedDay = null), Index 1+ = specific day
        if (index == 0) {
          viewModel.onPageChanged(viewModel.year, viewModel.month, null);
        } else {
          viewModel.onPageChanged(viewModel.year, viewModel.month, index);
        }
      },
      controller: viewModel.pageController,
      itemCount: daysInMonth + 1, // +1 for "all" page
      itemBuilder: (context, index) {
        // Index 0 shows all stories for the month
        if (index == 0) {
          return SpStoryList.withQuery(
            disableMultiEdit: true,
            filter: viewModel.searchFilter,
          );
        }

        // Index 1+ shows stories for specific day
        final day = index;
        return SpStoryList.withQuery(
          disableMultiEdit: true,
          filter: SearchFilterObject(
            years: {viewModel.year},
            month: viewModel.month,
            day: day,
            types: {PathType.docs},
            tagId: viewModel.selectedTagId,
            assetId: null,
          ),
        );
      },
    );
  }

  Widget buildCalendar({
    required bool showBottomBorder,
  }) {
    return SpCalendar(
      showBottomBorder: showBottomBorder,
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
              ? () => viewModel.selectDay(
                  viewModel.year,
                  viewModel.month,
                  viewModel.selectedDay == date.day ? null : date.day,
                )
              : null,
        );
      },
    );
  }
}
