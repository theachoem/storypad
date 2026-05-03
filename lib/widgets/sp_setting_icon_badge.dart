import 'package:flutter/material.dart';
import 'package:storypad/core/services/color_from_day_service.dart';

class SpSettingIconBadge extends StatelessWidget {
  const SpSettingIconBadge({
    super.key,
    required this.weekday,
    required IconData icon,
  }) : _iconData = icon,
       _child = null;

  const SpSettingIconBadge.widget({
    super.key,
    required this.weekday,
    required Widget child,
  }) : _child = child,
       _iconData = null;

  final int weekday;
  final IconData? _iconData;
  final Widget? _child;

  @override
  Widget build(BuildContext context) {
    final color = ColorFromDayService(context: context).get(weekday)!;
    final foreground = ColorFromDayService(context: context).getForeground()!;
    final child = IconTheme(
      data: IconThemeData(color: foreground, size: 24),
      child: _child ?? Icon(_iconData!),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
