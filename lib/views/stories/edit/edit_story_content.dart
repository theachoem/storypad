part of 'edit_story_view.dart';

class _EditStoryContent extends StatelessWidget {
  const _EditStoryContent(this.viewModel);

  final EditStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => viewModel.onPopInvokedWithResult(didPop, result, context),
      child: Scaffold(
        endDrawer: viewModel.story != null
            ? TagsEndDrawer(
                onUpdated: (tags) => viewModel.setTags(tags),
                initialTags: viewModel.story?.validTags ?? [],
              )
            : null,
        appBar: AppBar(
          leading: SpAnimatedIcons.fadeScale(
            firstChild: CloseButton(onPressed: () => viewModel.toggleManagingPage()),
            secondChild: BackButton(),
            showFirst: viewModel.managingPage,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          titleSpacing: 0.0,
          actions: buildAppBarActions(context),
        ),
        body: buildBody(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.quillControllers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    } else {
      return IndexedStack(
        index: viewModel.managingPage ? 1 : 0,
        children: [
          buildPageEditors(),
          StoryPagesManager(state: viewModel),
        ],
      );
    }
  }

  Widget buildPageEditors() {
    return PageView.builder(
      key: ValueKey(viewModel.quillControllers.length),
      controller: viewModel.pageController,
      itemCount: viewModel.quillControllers.length,
      itemBuilder: (context, index) {
        return buildPage(index);
      },
    );
  }

  Widget buildPage(int index) {
    return PrimaryScrollController(
      controller: viewModel.scrollControllers[index],
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, _) {
          String? feeling = viewModel.draftContent?.richPages?[index].feeling;
          if (index == 0) feeling ??= viewModel.story?.feeling;

          return [
            if (viewModel.story != null && viewModel.draftContent != null)
              SliverToBoxAdapter(
                child: StoryHeader(
                  paddingTop: MediaQuery.of(context).padding.top + 8.0,
                  story: viewModel.story!,
                  feeling: feeling,
                  setFeeling: (feeling) => viewModel.setFeeling(feeling),
                  onToggleShowDayCount: viewModel.toggleShowDayCount,
                  onToggleShowTime: viewModel.toggleShowTime,
                  draftContent: viewModel.draftContent!,
                  readOnly: false,
                  titleController: viewModel.titleControllers[index],
                  onChangeDate: viewModel.changeDate,
                  draftActions: null,
                ),
              ),
            SpSliverStickyDivider.sliver(),
          ];
        },
        body: Builder(builder: (context) {
          return _Editor(
            draftContent: viewModel.draftContent,
            controller: viewModel.quillControllers[index],
            focusNode: viewModel.focusNodes[index],
            scrollController: PrimaryScrollController.maybeOf(context) ?? ScrollController(),
          );
        }),
      ),
    );
  }

  List<Widget> buildAppBarActions(BuildContext context) {
    return [
      if (!viewModel.managingPage) ...[
        if (viewModel.draftContent?.richPages?.length != null && viewModel.draftContent!.richPages!.length > 1) ...[
          buildPageIndicator(),
          const SizedBox(width: 16.0),
        ],
        SizedBox(width: 8.0),
        Builder(builder: (context) {
          return IconButton(
            tooltip: tr("page.tags.title"),
            icon: Icon(SpIcons.of(context).tag),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          );
        }),
        IconButton(
          tooltip: tr("page.theme.title"),
          icon: Icon(SpIcons.of(context).theme),
          onPressed: () => SpStoryThemeBottomSheet(
            story: viewModel.story!,
            onThemeChanged: (preferences) => viewModel.changePreferences(preferences),
          ).show(context: context),
        ),
      ],
      Builder(builder: (context) {
        return IconButton(
          tooltip: tr("button.manage_pages"),
          icon: Icon(
            viewModel.managingPage ? SpIcons.of(context).managingPage : SpIcons.of(context).managingPageOff,
            color: viewModel.managingPage ? ColorScheme.of(context).tertiary : null,
          ),
          onPressed: () => viewModel.toggleManagingPage(),
        );
      }),
      const SizedBox(width: 8.0),
      ValueListenableBuilder(
        valueListenable: viewModel.lastSavedAtNotifier,
        builder: (context, lastSavedAt, child) {
          return OutlinedButton.icon(
            icon: SpAnimatedIcons(
              firstChild: Icon(SpIcons.of(context).save),
              secondChild: Icon(SpIcons.of(context).check),
              showFirst: lastSavedAt == null,
            ),
            label: Text(tr("button.done")),
            onPressed: lastSavedAt == null ? null : () => viewModel.done(context),
          );
        },
      ),
      const SizedBox(width: 12.0),
    ];
  }

  Widget buildPageIndicator() {
    return Container(
      height: 48.0,
      alignment: Alignment.center,
      child: ValueListenableBuilder<double>(
        valueListenable: viewModel.currentPageNotifier,
        builder: (context, currentPage, child) {
          return Text('${viewModel.currentPage + 1} / ${viewModel.draftContent?.richPages?.length}');
        },
      ),
    );
  }
}
