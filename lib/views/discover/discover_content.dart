part of 'discover_view.dart';

class _DiscoverContent extends StatelessWidget {
  const _DiscoverContent(this.viewModel);

  final DiscoverViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight,
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
        bottom: CupertinoSheetRoute.hasParentSheet(context)
            ? const PreferredSize(preferredSize: Size.fromHeight(48), child: SizedBox())
            : null,
        flexibleSpace: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            width: double.infinity,
            child: SegmentedButton<DiscoverSegmentId>(
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
            ),
          ),
        ),
      ),
      body: IndexedStack(
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
    );
  }
}
