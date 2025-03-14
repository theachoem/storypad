part of '../home_view.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      actions: const [SizedBox()],
      automaticallyImplyLeading: false,
      pinned: true,
      floating: true,
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      forceElevated: false,
      expandedHeight: viewModel.scrollInfo.appBar(context).getExpandedHeight(),
      flexibleSpace: _HomeFlexibleSpaceBar(viewModel: viewModel),
      bottom: buildTabBar(context),
    );
  }

  PreferredSize buildTabBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(viewModel.scrollInfo.appBar(context).getTabBarPreferredHeight()),
      child: _HomeTabBar(viewModel: viewModel),
    );
  }
}
