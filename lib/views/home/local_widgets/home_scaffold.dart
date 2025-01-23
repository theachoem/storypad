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
  final Widget appBar;
  final Widget body;
  final Widget floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      body: Builder(builder: (context) {
        return Stack(
          children: [
            const StoryListTimelineVerticleDivider(),
            RefreshIndicator.adaptive(
              edgeOffset: viewModel.scrollInfo.appBar(context).getExpandedHeight() + MediaQuery.of(context).padding.top,
              onRefresh: () => refresh(context),
              child: CustomScrollView(
                controller: viewModel.scrollInfo.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  appBar,
                  body,
                ],
              ),
            ),
            const _AppUpdateFloatingButton(),
          ],
        );
      }),
    );
  }

  Future<void> refresh(BuildContext context) async {
    await viewModel.load(debugSource: '$runtimeType#refresh');
    if (context.mounted) await context.read<BackupProvider>().recheck();
  }
}
