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
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        enableFeedback: true,
        tabAlignment: TabAlignment.start,
        isScrollable: true,
        indicatorAnimation: TabIndicatorAnimation.linear,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.only(
          left: 14.0,
          right: 14.0,
          top: viewModel.scrollInfo.appBar(context).indicatorPaddingTop,
          bottom: viewModel.scrollInfo.appBar(context).indicatorPaddingBottom,
        ),
        indicator: RoundedIndicator.simple(
          height: viewModel.scrollInfo.appBar(context).indicatorHeight,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: (index) {
          viewModel.scrollInfo.moveToMonthIndex(
            months: viewModel.months,
            targetMonthIndex: index,
            context: context,
          );
        },
        splashBorderRadius: BorderRadius.circular(viewModel.scrollInfo.appBar(context).indicatorHeight / 2),
        tabs: viewModel.months.map((month) {
          return buildMonthTab(context, month);
        }).toList(),
      ),
    );
  }

  Widget buildMonthTab(BuildContext context, int month) {
    return Container(
      height: viewModel.scrollInfo.appBar(context).indicatorHeight - 2,
      alignment: Alignment.center,
      child: Text(DateFormatHelper.MMM(DateTime(2000, month), context.locale)),
    );
  }
}
