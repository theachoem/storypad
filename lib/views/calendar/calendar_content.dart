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
      child: CupertinoSheetRoute.hasParentSheet(context)
          ? Container(
              padding: const EdgeInsets.only(top: 12.0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: buildScaffold(tags, context),
            )
          : buildScaffold(tags, context),
    );
  }

  Widget buildScaffold(List<TagDbModel> tags, BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(tags, context),
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
                  viewModel.tabIndex,
                ),
              ),
            ),
          ];
        },
        body: SpStoryList.withQuery(
          key: ValueKey(viewModel.editedKey),
          disableMultiEdit: true,
          filter: viewModel.filter,
        ),
      ),
    );
  }

  AppBar buildAppBar(List<TagDbModel> tags, BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      centerTitle: true,
      bottom: tags.length == 1
          ? const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1))
          : buildTagsTabBar(tags, context),
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
              viewModel.tabIndex,
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
            viewModel.tabIndex,
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(SpIcons.keyboardRight),
          onPressed: () {
            viewModel.onChanged(
              viewModel.month + 1 == 13 ? viewModel.year + 1 : viewModel.year,
              viewModel.month + 1 == 13 ? 1 : viewModel.month + 1,
              viewModel.selectedDay,
              viewModel.selectedTagId,
              viewModel.tabIndex,
            );
          },
        ),
      ],
    );
  }

  TabBar buildTagsTabBar(List<TagDbModel> tags, BuildContext context) {
    return TabBar(
      onTap: (index) {
        TagDbModel tag = tags[index];
        viewModel.onChanged(viewModel.year, viewModel.month, null, tag.id == 0 ? null : tag.id, index);
      },
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: List.generate(tags.length, (index) {
        return Tab(
          child: Row(
            spacing: 8.0,
            children: [
              Text(tags[index].title),
              if (viewModel.currentStoryCountByTabIndex[index] != null && index == viewModel.tabIndex)
                SpFadeIn.bound(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: ColorScheme.of(context).primary,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text(
                      viewModel.currentStoryCountByTabIndex[index].toString(),
                      style: TextStyle(
                        color: ColorScheme.of(context).onPrimary,
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      }),
    );
  }
}
