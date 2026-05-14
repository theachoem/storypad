import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';

class SpCapacityBadge extends StatelessWidget {
  const SpCapacityBadge({
    super.key,
    required this.current,
    required this.max,
  });

  final int current;
  final int max;

  double get _capacity => max > 0 ? current / max : 0.0;
  bool get _limitReached => current >= max;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final backgroundColor = _limitReached
        ? colorScheme.errorContainer
        : _capacity >= 0.8
        ? colorScheme.bootstrap.warning.container
        : colorScheme.primaryContainer;
    final foregroundColor = _limitReached
        ? colorScheme.onErrorContainer
        : _capacity >= 0.8
        ? colorScheme.bootstrap.warning.onContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$current/$max',
        style: TextTheme.of(context).labelMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
