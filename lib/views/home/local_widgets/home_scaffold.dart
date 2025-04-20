part of '../home_view.dart';

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({
    required this.endDrawer,
    required this.viewModel,
    required this.appBar,
    required this.body,
    required this.floatingActionButton,
    required this.bottomNavigationBar,
  });

  final HomeViewModel viewModel;
  final Widget? endDrawer;
  final Widget appBar;
  final Widget body;
  final Widget floatingActionButton;
  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          kIsCupertino && AppTheme.isDarkMode(context) && AppTheme.isMonochrome(context) ? Colors.black : null,
      resizeToAvoidBottomInset: false,
      endDrawerEnableOpenDragGesture: true,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: true,
      body: Stack(
        children: [
          const SpSpStoryListTimelineVerticleDivider(),
          RefreshIndicator.adaptive(
            edgeOffset: viewModel.scrollInfo.appBar(context).getExpandedHeight() + MediaQuery.of(context).padding.top,
            onRefresh: () => viewModel.refresh(context),
            child: CustomScrollView(
              controller: viewModel.scrollInfo.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                appBar,
                body,
              ],
            ),
          ),
          // TODO: add something to home side bar
          // buildTimelineSideBar(context),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 12.0,
            child: const _AppUpdateFloatingButton(),
          ),
        ],
      ),
    );
  }

  Widget buildTimelineSideBar(BuildContext viewContext) {
    return Positioned(
      bottom: 0,
      child: SpStoryListMultiEditWrapper.listen(
        context: viewContext,
        builder: (context, state) {
          return Visibility(
            visible: !state.editing,
            child: Container(
              padding: EdgeInsets.only(
                left: AppTheme.getDirectionValue(viewContext, 0.0, MediaQuery.of(viewContext).padding.left + 14.0)!,
                right: AppTheme.getDirectionValue(viewContext, MediaQuery.of(viewContext).padding.left + 14.0, 0.0)!,
                bottom: MediaQuery.of(viewContext).padding.bottom + 24.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  end: Alignment.topCenter,
                  begin: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.0)
                  ],
                ),
              ),
              child: const _HomeTimelineSideBar(),
            ),
          );
        },
      ),
    );
  }
}
