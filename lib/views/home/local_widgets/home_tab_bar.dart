part of '../home_view.dart';

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: 14.0,
              right: 14.0,
              top: viewModel.scrollInfo.appBar(context).indicatorPaddingTop,
              bottom: viewModel.scrollInfo.appBar(context).indicatorPaddingBottom,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                enableFeedback: true,
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                indicatorAnimation: TabIndicatorAnimation.linear,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.zero,
                indicator: _RoundedIndicator.simple(
                  height: viewModel.scrollInfo.appBar(context).indicatorHeight - 1.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: (index) {
                  viewModel.scrollInfo.moveToMonthIndex(
                    targetMonthIndex: index,
                    context: context,
                  );
                },
                dividerHeight: 0.0,
                splashBorderRadius: BorderRadius.circular(viewModel.scrollInfo.appBar(context).indicatorHeight / 2),
                tabs: viewModel.months.map((month) {
                  return buildMonthTab(context, month);
                }).toList(),
              ),
            ),
          ),
        ),
        SizedBox(
          height: viewModel.scrollInfo.appBar(context).getTabBarPreferredHeight(),
          child: Center(child: buildOpenEndDrawerButton(context)),
        ),
      ],
    );
  }

  Widget buildMonthTab(BuildContext context, int month) {
    return Container(
      height: viewModel.scrollInfo.appBar(context).indicatorHeight - 2,
      alignment: Alignment.center,
      child: Text(DateFormatHelper.MMM(DateTime(2000, month), context.locale)),
    );
  }

  Widget buildOpenEndDrawerButton(BuildContext context) {
    return IconButton(
      onPressed: () => viewModel.openSettings(context),
      tooltip: tr("button.more_options"),
      icon: const Icon(SpIcons.moreVert),
    );
  }
}
