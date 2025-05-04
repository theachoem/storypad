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
    List<Widget> buttons = [
      // buildButton(
      //   context: context,
      //   child: const Icon(SpIcons.addFeeling, size: 24.0),
      //   onTap: () {},
      // ),
      // buildButton(
      //   context: context,
      //   child: const Icon(SpIcons.tag, size: 24.0),
      //   onTap: () {
      //     TagsRoute().push(context);
      //   },
      // ),
      buildButton(
        context: context,
        child: const Icon(SpIcons.calendar, size: 24.0),
        onTap: () => viewModel.openDiscoverView(context),
      ),
    ];

    double blockColorHeight = screenPadding.bottom + 12 + baseIconHorizontalPadding / 2;
    blockColorHeight += (buttons.length - 1) * iconSize; // block background for all buttons except last one
    blockColorHeight += iconSize / 2; // block half of last button
    blockColorHeight += buttons.length * baseIconVerticlePadding; // block spacing between all buttons

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
              height: blockColorHeight,
              color: showClickableAria ? Colors.red : backgroundColor.withValues(alpha: 0.9),
            ),
          ),
        ),
        Positioned(
          bottom: blockColorHeight,
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
                    (showClickableAria ? Colors.green : backgroundColor).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: bottomPadding,
            left: AppTheme.getDirectionValue(context, 0, screenPadding.left)!,
            right: AppTheme.getDirectionValue(context, screenPadding.right, 0)!,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 0.0,
            children: buttons,
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
