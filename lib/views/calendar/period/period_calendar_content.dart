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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1),
        ),
      ),
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
    return Row(
      children: [
        Flexible(child: buildCalendar(showBottomBorder: false)),
        const VerticalDivider(),
        Flexible(child: buildStoryList(context)),
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
      body: buildStoryList(context),
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
  }

  Widget buildStoryList(BuildContext context) {
    if (viewModel.selectedEventStories?.items == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (viewModel.selectedEventStories?.items.isEmpty == true) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          tr('general.no_story_yet'),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: .center,
        ),
      );
    }

    return SpStoryList(
      stories: viewModel.selectedEventStories,
      onChanged: (item) => viewModel.load(initialSelectedDate: viewModel.selectedEventDate),
      onDeleted: () => viewModel.load(initialSelectedDate: viewModel.selectedEventDate),
    );
  }
}
