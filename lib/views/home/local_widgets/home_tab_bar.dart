part of '../home_view.dart';

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
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
            right: 14.0 + 36.0,
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
        buildFilterIconButton(context)
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

  Widget buildFilterIconButton(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 1,
      child: Center(
        child: Container(
          padding: EdgeInsets.only(right: 4.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [0.0, 0.3],
              colors: [
                Theme.of(context).appBarTheme.backgroundColor!.withValues(alpha: 0.0),
                Theme.of(context).appBarTheme.backgroundColor!,
              ],
            ),
          ),
          child: SpAnimatedIcons.fadeScale(
            duration: Durations.long1,
            firstChild: buildButton(context, true),
            secondChild: buildButton(context, false),
            showFirst: viewModel.filtered,
          ),
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, bool filtered) {
    return IconButton(
      tooltip: tr("page.search_filter.title"),
      color: filtered ? ColorScheme.of(context).bootstrap.info.color : null,
      iconSize: 20.0,
      icon: Icon(MdiIcons.tuneVariant),
      onPressed: () => viewModel.goToFilter(context),
    );
  }
}
