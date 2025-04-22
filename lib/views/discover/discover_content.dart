part of 'discover_view.dart';

class _DiscoverContent extends StatelessWidget {
  const _DiscoverContent(this.viewModel);

  final DiscoverViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: MediaQuery.removePadding(
        context: context,
        child: IndexedStack(
          index: viewModel.selectedIndex,
          children: viewModel.pages().map((page) {
            bool selected = page.id == viewModel.selectedPage;

            return Visibility(
              visible: selected,
              maintainState: viewModel.shouldMaintainState(page.id),
              child: page.page,
            );
          }).toList(),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      actions: [
        if (CupertinoSheetRoute.hasParentSheet(context))
          CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
      ],
      bottom: CupertinoSheetRoute.hasParentSheet(context)
          ? const PreferredSize(preferredSize: Size.fromHeight(36), child: SizedBox())
          : null,
      flexibleSpace: buidlSegmentButtons(context),
    );
  }

  Widget buidlSegmentButtons(BuildContext context) {
    Widget segmentButton;

    if (kIsCupertino) {
      segmentButton = CupertinoSlidingSegmentedControl<DiscoverSegmentId>(
        groupValue: viewModel.selectedPage,
        onValueChanged: (page) => viewModel.switchSelectedPage(page!),
        children: {
          for (final page in viewModel.pages()) page.id: Icon(page.icon),
        },
      );
    } else {
      segmentButton = SegmentedButton<DiscoverSegmentId>(
        selected: {viewModel.selectedPage},
        multiSelectionEnabled: false,
        onSelectionChanged: (value) => viewModel.switchSelectedPage(value.first),
        showSelectedIcon: false,
        segments: viewModel.pages().map((e) {
          return ButtonSegment(
            value: e.id,
            tooltip: e.tooltip,
            icon: Icon(e.icon),
          );
        }).toList(),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4.0,
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        width: double.infinity,
        child: segmentButton,
      ),
    );
  }
}
