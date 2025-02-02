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
      ValueListenableBuilder(
        valueListenable: viewModel.lastSavedAtNotifier,
        builder: (context, lastSavedAt, child) {
          return OutlinedButton.icon(
            icon: SpAnimatedIcons(
              firstChild: Icon(Icons.save),
              secondChild: Icon(Icons.done),
              showFirst: lastSavedAt == null,
            ),
            label: Text("Done"),
            onPressed: lastSavedAt == null
                ? null
                : () async {
                    await viewModel.save();
                    if (context.mounted) Navigator.pop(context);
                  },
          );
        },
      ),
      SizedBox(width: 8.0),
      Builder(builder: (context) {
        return IconButton(
          icon: const Icon(Icons.sell_outlined),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        );
      }),
      const SizedBox(width: 4.0),
    ];
  }
}
