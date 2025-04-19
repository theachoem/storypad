part of 'discover_view.dart';

class _DiscoverContent extends StatelessWidget {
  const _DiscoverContent(this.viewModel);

  final DiscoverViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 48.0 + 12.0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            width: double.infinity,
            child: SegmentedButton<String>(
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
        children: viewModel.pages().map((e) {
          return AnimatedContainer(
            curve: Curves.ease,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()..translate(0.0, e.id == viewModel.selectedPage ? 0.0 : 12.0),
            duration: Durations.long1,
            child: AnimatedOpacity(
              opacity: e.id == viewModel.selectedPage ? 1.0 : 0.0,
              duration: Durations.long2,
              child: e.page,
            ),
          );
        }).toList(),
      ),
    );
  }
}
