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
    return SpSingleStateWidget(
      initialValue: false,
      builder: (context, endDrawerOpenedNotifier) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          endDrawerEnableOpenDragGesture: true,
          endDrawer: endDrawer,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          onEndDrawerChanged: AppTheme.isIOS(context) ? (isOpened) => endDrawerOpenedNotifier.value = isOpened : null,
          body: ValueListenableBuilder(
            valueListenable: endDrawerOpenedNotifier,
            child: Stack(
              children: [
                const SpSpStoryListTimelineVerticleDivider(),
                RefreshIndicator.adaptive(
                  edgeOffset:
                      viewModel.scrollInfo.appBar(context).getExpandedHeight() + MediaQuery.of(context).padding.top,
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
                  child: _AppUpdateFloatingButton(),
                ),
              ],
            ),
            builder: (context, endDrawerOpened, child) {
              return AnimatedContainer(
                transform: Matrix4.identity()..translate(endDrawerOpened ? -304.0 / 2 : 0.0, 0.0),
                duration: Durations.long1,
                curve: Curves.ease,
                child: child,
              );
            },
          ),
        );
      },
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
              child: _HomeTimelineSideBar(),
            ),
          );
        },
      ),
    );
  }
}
