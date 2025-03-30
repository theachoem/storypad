part of 'show_story_view.dart';

class _ShowStoryContent extends StatelessWidget {
  const _ShowStoryContent(this.viewModel);

  final ShowStoryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: viewModel.story != null
          ? TagsEndDrawer(
              onUpdated: (tags) => viewModel.setTags(tags),
              initialTags: viewModel.story?.validTags ?? [],
            )
          : null,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 0.0,
        actions: buildAppBarActions(context),
      ),
      body: bodyBody(context),
    );
  }

  Widget bodyBody(BuildContext context) {
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
      controller: viewModel.scrollControllers[index]!,
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, _) {
          String? feeling = viewModel.draftContent?.richPages?[index].feeling;
          if (index == 0) feeling ??= viewModel.story?.feeling;

          return [
            if (viewModel.story != null && viewModel.draftContent != null)
              SliverToBoxAdapter(
                child: StoryHeader(
                  titleController: viewModel.titleControllers[index],
                  paddingTop: MediaQuery.of(context).padding.top + 8.0,
                  story: viewModel.story!,
                  feeling: feeling,
                  setFeeling: (feeling) => viewModel.setFeeling(feeling),
                  onToggleShowDayCount: viewModel.toggleShowDayCount,
                  onToggleShowTime: viewModel.toggleShowTime,
                  draftContent: viewModel.draftContent!,
                  readOnly: true,
                  onChangeDate: viewModel.changeDate,
                  draftActions: viewModel.getDraftActions(context),
                ),
              ),
            SpSliverStickyDivider.sliver(),
          ];
        },
        body: Builder(builder: (context) {
          return buildEditor(
            index: index,
            context: context,
            scrollController: PrimaryScrollController.maybeOf(context) ?? ScrollController(),
          );
        }),
      ),
    );
  }

  Widget buildEditor({
    required int index,
    required BuildContext context,
    required ScrollController scrollController,
  }) {
    return QuillEditor.basic(
      controller: viewModel.quillControllers[index]!,
      scrollController: scrollController,
      config: QuillEditorConfig(
        contextMenuBuilder: (context, rawEditorState) => QuillContextMenuHelper.get(
          rawEditorState,
          editable: false,
          onEdit: () => viewModel.goToEditPage(context),
        ),
        scrollBottomInset: 88 + MediaQuery.of(context).viewPadding.bottom,
        scrollable: true,
        expands: true,
        placeholder: "...",
        padding: EdgeInsets.only(
          top: 16.0,
          bottom: 88 + MediaQuery.of(context).viewPadding.bottom,
          left: MediaQuery.of(context).padding.left + 16.0,
          right: MediaQuery.of(context).padding.right + 16.0,
        ),
        checkBoxReadOnly: false,
        autoFocus: false,
        enableScribble: false,
        showCursor: false,
        embedBuilders: [
          SpImageBlockEmbed(fetchAllImages: () => StoryExtractImageFromContentService.call(viewModel.draftContent)),
          SpDateBlockEmbed(),
        ],
        unknownEmbedBuilder: SpQuillUnknownEmbedBuilder(),
      ),
    );
  }

  List<Widget> buildAppBarActions(BuildContext context) {
    return [
      if (viewModel.draftContent?.richPages?.length != null && viewModel.draftContent!.richPages!.length > 1) ...[
        buildPageIndicator(),
        const SizedBox(width: 12.0),
      ],
      IconButton(
        tooltip: tr("button.edit"),
        onPressed: () => viewModel.goToEditPage(context),
        icon: const Icon(Icons.edit_outlined),
      ),
      Builder(builder: (context) {
        return IconButton(
          tooltip: tr("page.tags.title"),
          icon: const Icon(Icons.sell_outlined),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        );
      }),
      IconButton(
        tooltip: tr("page.theme.title"),
        icon: Icon(Icons.color_lens_outlined),
        onPressed: () => SpStoryThemeBottomSheet(
          story: viewModel.story!,
          onThemeChanged: (preferences) => viewModel.changePreferences(preferences),
        ).show(context: context),
      ),
      Builder(builder: (context) {
        return IconButton(
          tooltip: tr("button.manage_pages"),
          icon: Icon(MdiIcons.bookOpenOutline),
          onPressed: () => viewModel.toggleManagingPage(),
        );
      }),
      SpPopupMenuButton(
        items: (context) {
          return [
            SpPopMenuItem(
              leadingIconData: Icons.info_outline,
              title: tr("button.info"),
              onPressed: () => SpStoryInfoSheet(story: viewModel.story!).show(context: context),
            ),
          ];
        },
        builder: (callback) {
          return IconButton(
            tooltip: tr("button.more_options"),
            icon: Icon(Icons.more_vert),
            onPressed: callback,
          );
        },
      ),
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
