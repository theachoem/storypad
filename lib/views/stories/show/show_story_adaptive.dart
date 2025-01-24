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
        clipBehavior: Clip.none,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        titleSpacing: 0.0,
        title: buildAppBarTitle(context),
        actions: buildAppBarActions(context),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: PageView.builder(
        controller: viewModel.pageController,
        itemCount: viewModel.quillControllers.length,
        itemBuilder: (context, index) {
          return QuillEditor.basic(
            controller: viewModel.quillControllers[index]!,
            config: QuillEditorConfig(
              padding: const EdgeInsets.all(16.0),
              checkBoxReadOnly: false,
              showCursor: false,
              autoFocus: false,
              expands: true,
              embedBuilders: [
                ImageBlockEmbed(),
                DateBlockEmbed(),
              ],
              unknownEmbedBuilder: UnknownEmbedBuilder(),
            ),
          );
        },
      ),
    );
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
      buildSwapeableToRecentlySavedIcon(
        child: SpFeelingButton(
          feeling: viewModel.story?.feeling,
          onPicked: (feeling) => viewModel.setFeeling(feeling),
        ),
      ),
      const SizedBox(width: 4.0),
    ];
  }

  Widget buildSwapeableToRecentlySavedIcon({
    required Widget child,
  }) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: viewModel.lastSavedAtNotifier,
      child: child,
      builder: (context, lastSavedAt, child) {
        DateTime defaultExpiredEndTime = DateTime.now().subtract(const Duration(days: 1));
        return SpCountDown(
          endTime: lastSavedAt?.add(const Duration(seconds: 2)) ?? defaultExpiredEndTime,
          endWidget: child!,
          builder: (ended, context) {
            return SpAnimatedIcons(
              duration: Durations.long1,
              showFirst: ended,
              firstChild: child,
              secondChild: Builder(builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(48.0),
                    onTap: () => Navigator.maybePop(context),
                    child: const CircleAvatar(
                      child: Icon(Icons.check),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
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
