part of '../home_view.dart';

class _HomeTimelineSideBar extends StatelessWidget {
  const _HomeTimelineSideBar({
    required this.screenPadding,
    required this.backgroundColor,
  });

  final EdgeInsets screenPadding;
  final Color backgroundColor;
  static const double iconSize = SpStoryTile.monogramSize + 8;

  @override
  Widget build(BuildContext context) {
    double baseHorizontalPadding = 6.0;

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.getDirectionValue(context, 0.0, screenPadding.left + baseHorizontalPadding)!,
        right: AppTheme.getDirectionValue(context, screenPadding.right + baseHorizontalPadding, 0.0)!,
        top: screenPadding.bottom + 24.0,
        bottom: screenPadding.bottom + 24.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          end: Alignment.topCenter,
          begin: Alignment.bottomCenter,
          colors: [
            backgroundColor.withValues(alpha: 0.0),
            backgroundColor.withValues(alpha: 0.8),
            backgroundColor,
            backgroundColor.withValues(alpha: 0.8),
            backgroundColor.withValues(alpha: 0.0)
          ],
        ),
      ),
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
            onTap: () {
              SpDiscoverSheet(
                params: const DiscoverRoute(),
              ).show(context: context);
            },
          ),
        ],
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }
}
