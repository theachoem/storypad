import 'package:flutter/material.dart';

class SpMapSideButton extends StatelessWidget {
  const SpMapSideButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44.0,
    this.isDanger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18.0,
              offset: const Offset(0.0, 8.0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Icon(icon, size: 20.0, color: isDanger ? colorScheme.error : null),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
