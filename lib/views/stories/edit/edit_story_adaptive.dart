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
                  readOnly: false,
                  titleController: viewModel.titleController,
                  onSetDate: viewModel.setDate,
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
          return _Editor(
            focusNode: viewModel.focusNodes[index]!,
            controller: viewModel.quillControllers[index]!,
            draftContent: viewModel.draftContent,
          );
        },
      );
    }
  }

  List<Widget> buildAppBarActions(BuildContext context) {
    return [
      OutlinedButton.icon(
        icon: Icon(Icons.check),
        label: Text("Done"),
        onPressed: () async {
          await viewModel.save();
          if (context.mounted) Navigator.pop(context);
        },
      ),
      SizedBox(width: 8.0),
      buildSwapeableToRecentlySavedIcon(
        child: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.sell_outlined),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          );
        }),
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
          endTime: lastSavedAt?.add(Durations.long4) ?? defaultExpiredEndTime,
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
