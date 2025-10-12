part of 'calendar_view.dart';

class _CalendarContent extends StatelessWidget {
  const _CalendarContent(this.viewModel);

  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (CupertinoSheetRoute.hasParentSheet(context)) {
      return Container(
        padding: const EdgeInsets.only(top: 12.0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: buildScaffold(context),
      );
    } else {
      return buildScaffold(context);
    }
  }

  Widget buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: tr("button.new_story"),
        child: const Icon(SpIcons.newStory),
        onPressed: () => viewModel.goToNewPage(context),
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
                onToggle: (TagDbModel tag) => viewModel.onChanged(
                  viewModel.year,
                  viewModel.month,
                  null,
                  tag.id == 0 ? null : tag.id,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SpCalendar(
                initialYear: viewModel.year,
                initialMonth: viewModel.month,
                selectedDay: viewModel.selectedDay,
                feelingMapByDay: viewModel.feelingMapByDay,
                onMonthChanged: viewModel.onMonthChanged,
                onDaySelected: viewModel.onDaySelected,
                controller: viewModel.calendarController,
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

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: SpTapEffect(
        onTap: () async {
          final result = await MonthPickerService(
            context: context,
            month: viewModel.month,
            year: viewModel.year,
          ).showPicker();
          if (result != null) {
            viewModel.navigateToMonth(result.year, result.month);
          }
        },
        child: Text(
          DateFormatHelper.yMMMM(DateTime(viewModel.year, viewModel.month, 1), context.locale),
          key: ValueKey("${viewModel.month}-${viewModel.year}"),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      leading: IconButton(
        icon: const Icon(SpIcons.keyboardLeft),
        onPressed: () {
          final newMonth = viewModel.month - 1 == 0 ? 12 : viewModel.month - 1;
          final newYear = viewModel.month - 1 == 0 ? viewModel.year - 1 : viewModel.year;
          viewModel.navigateToMonth(newYear, newMonth);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(SpIcons.keyboardRight),
          onPressed: () {
            final newMonth = viewModel.month + 1 == 13 ? 1 : viewModel.month + 1;
            final newYear = viewModel.month + 1 == 13 ? viewModel.year + 1 : viewModel.year;
            viewModel.navigateToMonth(newYear, newMonth);
          },
        ),
      ],
    );
  }
}
