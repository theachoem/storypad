part of '../backups_view.dart';

class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider({
    required this.avatarSize,
    required this.context,
  });

  final double avatarSize;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: AppTheme.getDirectionValue(context, null, (avatarSize + 12) / 2),
      right: AppTheme.getDirectionValue(context, (avatarSize + 12) / 2, null),
      child: const VerticalDivider(
        width: 1,
        indent: 0.0,
      ),
    );
  }
}
