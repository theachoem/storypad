part of 'show_story_view.dart';

class _ShowStoryAdaptive extends StatelessWidget {
  const _ShowStoryAdaptive(this.viewModel);

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
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, _) {
          return [
            if (viewModel.story != null && viewModel.draftContent != null)
              SliverToBoxAdapter(
                child: StoryHeader(
                  paddingTop: MediaQuery.of(context).padding.top + 8.0,
                  story: viewModel.story!,
                  setFeeling: viewModel.setFeeling,
                  onToggleShowDayCount: viewModel.toggleShowDayCount,
                  draftContent: viewModel.draftContent!,
                  readOnly: true,
                  onSetDate: null,
                ),
              ),
          ];
        },
        body: buildEditor(context),
      ),
    );
  }

  Widget buildEditor(BuildContext context) {
    if (viewModel.quillControllers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    } else {
      return PageView.builder(
        controller: viewModel.pageController,
        itemCount: viewModel.quillControllers.length,
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: QuillEditor.basic(
              controller: viewModel.quillControllers[index]!,
              config: QuillEditorConfig(
                scrollBottomInset: 88 + MediaQuery.of(context).viewPadding.bottom,
                scrollable: false,
                expands: false,
                placeholder: "...",
                padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(
                  top: 8.0,
                  bottom: 88 + MediaQuery.of(context).viewPadding.bottom,
                ),
                checkBoxReadOnly: false,
                autoFocus: false,
                enableScribble: false,
                showCursor: false,
                embedBuilders: [
                  ImageBlockEmbed(fetchAllImages: () => QuillService.imagesFromContent(viewModel.draftContent)),
                  DateBlockEmbed(),
                ],
                unknownEmbedBuilder: UnknownEmbedBuilder(),
              ),
            ),
          );
        },
      );
    }
  }

  Widget buildAppBarTitle(BuildContext context) {
    return SpPopupMenuButton(
      dxGetter: (dx) => dx + 96,
      dyGetter: (dy) => dy + 48,
      builder: (void Function() callback) {
        return StoryTitle(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          content: viewModel.draftContent,
          changeTitle: () => callback(),
        );
      },
      items: (BuildContext context) {
        return [
          SpPopMenuItem(
            title: 'Rename',
            leadingIconData: Icons.edit,
            onPressed: () => viewModel.renameTitle(context),
          ),
          SpPopMenuItem(
            title: 'Changes History',
            subtitle: "${viewModel.story?.rawChanges?.length}",
            leadingIconData: Icons.history,
            onPressed: () => viewModel.goToChangesPage(context),
          ),
        ];
      },
    );
  }

  List<Widget> buildAppBarActions(BuildContext context) {
    return [
      if (viewModel.draftContent?.pages?.length != null && viewModel.draftContent!.pages!.length > 1)
        buildPageIndicator(),
      const SizedBox(width: 12.0),
      IconButton(
        onPressed: () => viewModel.goToEditPage(context),
        icon: const Icon(Icons.edit_outlined),
      ),
      Builder(builder: (context) {
        return IconButton(
          icon: const Icon(Icons.sell_outlined),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        );
      }),
      const SizedBox(width: 4.0),
    ];
  }

  Widget buildPageIndicator() {
    return Container(
      height: 48.0,
      alignment: Alignment.center,
      child: ValueListenableBuilder<double>(
        valueListenable: viewModel.currentPageNotifier,
        builder: (context, currentPage, child) {
          return Text('${viewModel.currentPage + 1} / ${viewModel.draftContent?.pages?.length}');
        },
      ),
    );
  }
}

class UnknownEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return const Text("Unknown");
  }

  @override
  String get key => "unknown";
}
