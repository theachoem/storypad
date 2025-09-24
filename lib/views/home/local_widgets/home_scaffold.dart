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

  Color? getBackgroundColor(BuildContext context) {
    return kIsCupertino && AppTheme.isDarkMode(context) && AppTheme.isMonochrome(context) ? Colors.black : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getBackgroundColor(context),
      resizeToAvoidBottomInset: false,
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
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
          buildTimelineSideBar(context),
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
            child: _HomeTimelineSideBar(
              viewModel: viewModel,
              // when bottom navigation is visible, we should use context for screen padding.
              // else if bottom nav is not visible, padding from context is 0, so we use view context for padding instead.
              screenPadding: MediaQuery.of(context).padding.bottom == 0
                  ? MediaQuery.of(viewContext).padding
                  : MediaQuery.of(context).padding,
              backgroundColor: getBackgroundColor(context) ?? ColorScheme.of(context).surface,
            ),
          );
        },
      ),
    );
  }
}
