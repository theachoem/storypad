part of 'calendar_view.dart';

class _CalendarContent extends StatelessWidget {
  const _CalendarContent(this.viewModel);

  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        title: SpTapEffect(
          onTap: () async {
            final result =
                await MonthPickerService(context: context, month: viewModel.month, year: viewModel.year).showPicker();
            if (result != null) viewModel.onChanged(result.year, result.month, viewModel.selectedDay);
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              DateFormatHelper.yMMMM(DateTime(viewModel.year, viewModel.month, 1), context.locale),
              key: ValueKey("${viewModel.month}-${viewModel.year}"),
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(SpIcons.keyboardLeft),
          onPressed: () {
            viewModel.onChanged(
              viewModel.month - 1 == 0 ? viewModel.year - 1 : viewModel.year,
              viewModel.month - 1 == 0 ? 12 : viewModel.month - 1,
              viewModel.selectedDay,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(SpIcons.keyboardRight),
            onPressed: () {
              viewModel.onChanged(
                viewModel.month - 1 == 0 ? viewModel.year - 1 : viewModel.year,
                viewModel.month - 1 == 0 ? 12 : viewModel.month - 1,
                viewModel.selectedDay,
              );
            },
          ),
        ],
      ),
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
              child: _CalendarMonth(
                month: viewModel.month,
                year: viewModel.year,
                selectedDay: viewModel.selectedDay,
                feelingMapByDay: viewModel.feelingMapByDay,
                onChanged: (year, month, selectedDay) => viewModel.onChanged(year, month, selectedDay),
              ),
            ),
          ];
        },
        body: SpStoryList.withQuery(
          key: ValueKey(viewModel.editedKey),
          disableMultiEdit: true,
          filter: SearchFilterObject(
            years: {viewModel.year},
            month: viewModel.month,
            day: viewModel.selectedDay,
            types: {PathType.docs},
            tagId: null,
            assetId: null,
          ),
        ),
      ),
    );
  }
}
