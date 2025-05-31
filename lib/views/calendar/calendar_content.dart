part of 'calendar_view.dart';

class _CalendarContent extends StatelessWidget {
  const _CalendarContent(this.viewModel);

  final CalendarViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    TagsProvider tagProvider = Provider.of<TagsProvider>(context);

    final tags = <TagDbModel>[...tagProvider.tags?.items ?? []];
    tags.insert(0, TagDbModel.fromIDTitle(0, tr('general.all')));

    return DefaultTabController(
      length: tags.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: tags.length == 1
              ? const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1))
              : buildTagsTabBar(tags),
          title: SpTapEffect(
            onTap: () async {
              final result =
                  await MonthPickerService(context: context, month: viewModel.month, year: viewModel.year).showPicker();
              if (result != null) {
                viewModel.onChanged(
                  result.year,
                  result.month,
                  viewModel.selectedDay,
                  viewModel.selectedTagId,
                );
              }
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
                viewModel.selectedTagId,
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
                  viewModel.selectedTagId,
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
                  onChanged: (year, month, selectedDay) => viewModel.onChanged(
                    year,
                    month,
                    selectedDay,
                    viewModel.selectedTagId,
                  ),
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
              tagId: viewModel.selectedTagId,
              assetId: null,
            ),
          ),
        ),
      ),
    );
  }

  TabBar buildTagsTabBar(List<TagDbModel> tags) {
    return TabBar(
      onTap: (index) {
        TagDbModel tag = tags[index];
        viewModel.onChanged(
          viewModel.year,
          viewModel.month,
          viewModel.selectedDay,
          tag.id == 0 ? null : tag.id,
        );
      },
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: tags.map((tag) {
        return Tab(text: tag.title);
      }).toList(),
    );
  }
}
