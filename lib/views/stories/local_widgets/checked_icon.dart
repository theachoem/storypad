part of 'story_pages_manager.dart';

class _CheckedIcon extends StatelessWidget {
  const _CheckedIcon();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -4,
      right: -4,
      child: Container(
        decoration: BoxDecoration(
          color: ColorScheme.of(context).secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          SpIcons.check,
          color: ColorScheme.of(context).onSecondary,
          size: 16.0,
        ),
      ),
    );
  }
}
