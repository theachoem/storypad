part of '../home_view.dart';

class _HomeTimelineSideBar extends StatelessWidget {
  const _HomeTimelineSideBar();

  @override
  Widget build(BuildContext context) {
    final double iconSize = SpStoryTile.monogramSize + 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8.0,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.calendar_today_outlined,
            size: 24.0,
          ),
        ),
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_emotions_outlined,
            size: 24.0,
          ),
        ),
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.search),
        ),
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.home_outlined),
        ),
      ],
    );
  }
}
