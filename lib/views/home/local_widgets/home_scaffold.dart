part of '../home_view.dart';

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({
    required this.endDrawer,
    required this.viewModel,
    required this.appBar,
    required this.body,
    required this.floatingActionButton,
  });

  final HomeViewModel viewModel;
  final Widget? endDrawer;
  final SliverAppBar appBar;
  final SliverList body;
  final Widget floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const _TimelineVerticleDivider(),
          ListViewObserver(
            controller: viewModel.scrollInfo.observerScrollController,
            onObserve: (result) => viewModel.scrollInfo.onObserve(result, context),
            child: RefreshIndicator.adaptive(
              edgeOffset: viewModel.scrollInfo.getExpandedHeight(context) + 32.0,
              onRefresh: () => Future.delayed(Durations.medium4),
              child: CustomScrollView(
                controller: viewModel.scrollInfo.scrollController,
                slivers: [
                  appBar,
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    sliver: body,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
