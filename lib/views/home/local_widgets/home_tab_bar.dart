part of '../home_view.dart';

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    List<Widget> actionButtons = constructActionButtons(context);
    return Stack(
      children: [
        TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          enableFeedback: true,
          tabAlignment: TabAlignment.start,
          isScrollable: true,
          indicatorAnimation: TabIndicatorAnimation.linear,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.primary,
          padding: EdgeInsets.only(
            left: 14.0,
            right: 14.0 + actionButtons.length * 44,
            top: viewModel.scrollInfo.appBar(context).indicatorPaddingTop,
            bottom: viewModel.scrollInfo.appBar(context).indicatorPaddingBottom,
          ),
          indicator: _RoundedIndicator.simple(
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
        buildIconsButtonsWrapper(context, actionButtons)
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

  List<Widget> constructActionButtons(BuildContext context) {
    return [
      buildOpenEndDrawerButton(context),
    ];
  }

  Widget buildIconsButtonsWrapper(BuildContext context, List<Widget> actionButtons) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 1,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 4.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: [0.0, 0.3],
            colors: [
              viewModel.scrollInfo.appBar(context).getBackgroundColor(context).withValues(alpha: 0.0),
              viewModel.scrollInfo.appBar(context).getBackgroundColor(context),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: actionButtons,
        ),
      ),
    );
  }

  Widget buildOpenEndDrawerButton(BuildContext context) {
    return Consumer<AppLockProvider>(
      builder: (context, appLockProvider, child) {
        return IconButton(
          onPressed: () => viewModel.openEndDrawer(context),
          tooltip: tr("button.more_options"),
          icon: const Icon(SpIcons.moreVert),
        );
      },
    );
  }
}
