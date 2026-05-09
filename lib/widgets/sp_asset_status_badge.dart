import 'package:flutter/material.dart';

class SpAssetStatusBadge extends StatelessWidget {
  const SpAssetStatusBadge({
    super.key,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    this.tooltipMessage,
    this.radius = 12.0,
    this.iconSize = 14.0,
    this.top = 6.0,
    this.right = 6.0,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String? tooltipMessage;
  final double radius;
  final double iconSize;
  final double top;
  final double right;

  @override
  Widget build(BuildContext context) {
    final badge = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: Icon(icon, size: iconSize),
    );

    return Positioned(
      top: top,
      right: right,
      child: tooltipMessage == null
          ? badge
          : Tooltip(
              message: tooltipMessage,
              child: badge,
            ),
    );
  }
}
