part of '../home_view.dart';

class _HomeTimelineSideBar extends StatelessWidget {
  const _HomeTimelineSideBar({
    required this.screenPadding,
    required this.backgroundColor,
    required this.viewModel,
  });

  final EdgeInsets screenPadding;
  final Color backgroundColor;
  final HomeViewModel viewModel;

  static const double iconSize = SpStoryTile.monogramSize + 6;
  static const double baseIconVerticlePadding = 6.0;
  static const double baseIconHorizontalPadding = 13.0;
  static const double extraClickablePadding = 32.0;

  // for debugging
  static const bool showClickableAria = false;

  double get bottomPadding => screenPadding.bottom + 12.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: 0,
          left: AppTheme.getDirectionValue(context, null, screenPadding.left + baseIconHorizontalPadding),
          right: AppTheme.getDirectionValue(context, screenPadding.right + baseIconHorizontalPadding, null),
          child: Center(
            child: Container(
              width: iconSize,
              height: bottomPadding + iconSize / 2 + baseIconVerticlePadding,
              color: showClickableAria ? Colors.red : backgroundColor,
            ),
          ),
        ),
        Positioned(
          bottom: bottomPadding + iconSize / 2 + baseIconVerticlePadding,
          top: -16,
          left: AppTheme.getDirectionValue(context, null, screenPadding.left + baseIconHorizontalPadding),
          right: AppTheme.getDirectionValue(context, screenPadding.right + baseIconHorizontalPadding, null),
          child: Center(
            child: Container(
              width: iconSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (showClickableAria ? Colors.green : backgroundColor).withValues(alpha: 0.0),
                    (showClickableAria ? Colors.green : backgroundColor).withValues(alpha: 0.6),
                    (showClickableAria ? Colors.green : backgroundColor),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.0,
            children: [
              // buildButton(
              //   context: context,
              //   child: const Icon(SpIcons.addFeeling, size: 24.0),
              //   onTap: () {},
              // ),
              // buildButton(
              //   context: context,
              //   child: const Icon(SpIcons.search, size: 24.0),
              //   onTap: () {},
              // ),
              buildButton(
                context: context,
                child: const Icon(SpIcons.calendar, size: 24.0),
                onTap: () => viewModel.openDiscoverView(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildButton({
    required BuildContext context,
    required Widget child,
    required void Function()? onTap,
  }) {
    return SpTapEffect(
      scaleActive: 0.9,
      effects: [SpTapEffectType.scaleDown],
      onTap: onTap,
      child: Container(
        color: showClickableAria ? Colors.blue.withValues(alpha: 0.3) : null,
        padding: EdgeInsets.only(
          top: baseIconVerticlePadding,
          bottom: baseIconVerticlePadding,
          left: AppTheme.getDirectionValue(
            context,
            baseIconHorizontalPadding + extraClickablePadding,
            baseIconHorizontalPadding,
          )!,
          right: AppTheme.getDirectionValue(
            context,
            baseIconHorizontalPadding,
            baseIconHorizontalPadding + extraClickablePadding,
          )!,
        ),
        child: Container(
          width: iconSize,
          height: iconSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).appBarTheme.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }
}
