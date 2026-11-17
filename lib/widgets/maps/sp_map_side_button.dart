import 'package:flutter/material.dart';

/// A button over a map. With a [label], it's as tall as the others but widens to fit it, in the primary
/// color: an action about the user's own change (e.g. Reset, Cancel), set apart from the map's controls.
class SpMapSideButton extends StatelessWidget {
  const SpMapSideButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 48.0,
    this.isDanger = false,
    this.label,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;
  final bool isDanger;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);
    final String? label = this.label;
    final Color foregroundColor = isDanger
        ? colorScheme.error
        : label != null
        ? colorScheme.primary
        : colorScheme.onSurface;

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
            child: IconTheme(
              data: IconThemeData(color: foregroundColor),
              child: label == null
                  ? SizedBox.square(
                      dimension: size,
                      child: Center(child: icon),
                    )
                  : Container(
                      height: size,
                      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
                      child: Row(
                        mainAxisSize: .min,
                        spacing: 6.0,
                        children: [
                          icon,
                          Text(label, style: TextTheme.of(context).labelLarge?.copyWith(color: foregroundColor)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
