part of 'edit_story_view.dart';

class _EditStoryAdaptive extends StatelessWidget {
  const _EditStoryAdaptive(this.viewModel);

  final EditStoryViewModel viewModel;

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
        titleSpacing: 0.0,
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
        title: viewModel.story == null
            ? const SizedBox.shrink()
            : StoryTitle(
                content: viewModel.draftContent,
                changeTitle: () => viewModel.changeTitle(context),
                backgroundColor: ColorScheme.of(context).primary,
                scrollable: false,
              ),
        actions: buildAppBarActions(context),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (viewModel.quillControllers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    } else {
      return PageView.builder(
        controller: viewModel.pageController,
        itemCount: viewModel.quillControllers.length,
        itemBuilder: (context, index) {
          return _Editor(
            controller: viewModel.quillControllers[index]!,
            showToolbarOnTop: viewModel.showToolbarOnTop,
            showToolbarOnBottom: viewModel.showToolbarOnBottom,
            toggleToolbarPosition: viewModel.toggleToolbarPosition,
            draftContent: viewModel.draftContent,
          );
        },
      );
    }
  }

  List<Widget> buildAppBarActions(BuildContext context) {
    return [
      const SizedBox(width: 4.0),
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
          backgroundColor: ColorScheme.of(context).onPrimary.withValues(alpha: 0.15),
          foregroundColor: ColorScheme.of(context).onPrimary,
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
}
