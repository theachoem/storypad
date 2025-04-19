part of '../home_view.dart';

class _HomeFlexibleSpaceBar extends StatelessWidget {
  const _HomeFlexibleSpaceBar({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      collapseMode: CollapseMode.pin,
      background: Container(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.only(
          left: 16.0 + MediaQuery.of(context).padding.left,
          right: 16.0 + MediaQuery.of(context).padding.left,
          bottom: viewModel.scrollInfo.appBar(context).getTabBarPreferredHeight() +
              viewModel.scrollInfo.appBar(context).contentsMarginBottom,
        ),
        child: Stack(
          children: [
            buildGreetingMessage(context),
            buildYear(context),
          ],
        ),
      ),
    );
  }

  Widget buildGreetingMessage(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: AppTheme.getDirectionValue(context, viewModel.scrollInfo.appBar(context).getYearSize().width + 8.0, 0.0),
      right: AppTheme.getDirectionValue(context, 0.0, viewModel.scrollInfo.appBar(context).getYearSize().width + 8.0),
      child: SpTapEffect(
        onTap: () => viewModel.changeName(context),
        child: Container(
          alignment: AppTheme.getDirectionValue(context, Alignment.bottomRight, Alignment.bottomLeft),
          child: SpMeasureSize(
            onPerformLayout: (p0) {
              double actualHeight = p0.height;
              double caculatedHeight = viewModel.scrollInfo.appBar(context).getContentsHeight();

              // for adaptive text to font scaling, we precaculate the contents heights.
              // sometime when font is bigger, this question text render 2 line of text instead of 1.
              // our caculation is wrong because we only caculate for 1 line.
              //
              // because our render align all element to bottom, so it still responsive but just all text is getting near status bar or below it.
              // our solution is to just check how much we caculate wrong, add expanded height it a bit more.
              if (actualHeight > caculatedHeight && actualHeight - caculatedHeight > 1) {
                Future.microtask(() {
                  viewModel.scrollInfo.setExtraExpandedHeight(actualHeight - caculatedHeight);
                });
              } else {
                Future.microtask(() {
                  viewModel.scrollInfo.setExtraExpandedHeight(0);
                });
              }
            },
            child: Wrap(children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2.0,
                children: [
                  _HomeAppBarNickname(nickname: viewModel.nickname),
                  const _HomeAppBarMessage(),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget buildYear(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + viewModel.scrollInfo.appBar(context).contentsMarginTop,
      bottom: 0,
      left: AppTheme.getDirectionValue(context, 0.0, null),
      right: AppTheme.getDirectionValue(context, null, 0.0),
      child: Container(
        alignment: AppTheme.getDirectionValue(context, Alignment.topLeft, Alignment.topRight),
        width: viewModel.scrollInfo.appBar(context).getYearSize().width,
        height: viewModel.scrollInfo.appBar(context).getYearSize().height,
        margin: viewModel.scrollInfo.extraExpandedHeight > 0 ? const EdgeInsets.only(bottom: 8.0) : null,
        child: SpTapEffect(
          effects: const [SpTapEffectType.touchableOpacity],
          onTap: () {
            SpDiscoverSheet(
              params: const DiscoverRoute(),
            ).show(context: context);
          },
          child: FittedBox(
            child: Text(
              viewModel.year.toString(),
              overflow: TextOverflow.ellipsis,
              style: TextTheme.of(context).displayLarge?.copyWith(color: Theme.of(context).disabledColor, height: 1.0),
              textAlign: TextAlign.end,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
