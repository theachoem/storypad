part of '../home_view_model.dart';

class _HomeScrollAppBarInfo {
  final BuildContext context;
  final double extraExpandedHeight;
  late final TextScaler scaler;

  _HomeScrollAppBarInfo({
    required this.context,
    required this.extraExpandedHeight,
  }) {
    scaler = MediaQuery.textScalerOf(context);
  }

  final double contentsMarginTop = 24;
  final double helloTextBaseHeight = 28;
  final double questionTextBaseHeight = 24;
  final double contentsMarginBottom = 8;

  final double indicatorPaddingTop = 12;
  final double indicatorHeight = 40;
  final double indicatorPaddingBottom = 8;

  double getTabBarPreferredHeight() => indicatorPaddingTop + indicatorHeight + indicatorPaddingBottom;

  double getExpandedHeight() =>
      contentsMarginTop + getContentsHeight() + contentsMarginBottom + getTabBarPreferredHeight() + extraExpandedHeight;

  Size getYearSize(BoxConstraints appBarConstraints) {
    double aspectRatio = 24 / 10;
    double baseHeight = 52;
    double baseWidth = baseHeight * aspectRatio;

    // make sure not bigger than 2.5 of screen width.
    double actualWidth = min(appBarConstraints.maxWidth / 2.5, scaler.scale(baseWidth));
    double actualHeight = actualWidth / aspectRatio;

    return Size(actualWidth, actualHeight);
  }

  double getHelloTextHeight() => scaler.scale(helloTextBaseHeight);
  double getQuestionTextHeight() => scaler.scale(questionTextBaseHeight);
  double getContentsHeight() => getHelloTextHeight() + getQuestionTextHeight();

  Color getScaffoldBackgroundColor(BuildContext context) {
    return kIsCupertino && AppTheme.isDarkMode(context) && AppTheme.isMonochrome(context)
        ? Colors.black
        : Theme.of(context).scaffoldBackgroundColor;
  }

  Color getBackgroundColor(BuildContext context) =>
      AppTheme.isDarkMode(context) ? ColorScheme.of(context).readOnly.surface1! : ColorScheme.of(context).surface;
}
