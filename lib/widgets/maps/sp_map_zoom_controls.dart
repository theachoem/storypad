import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpMapZoomControls extends StatelessWidget {
  const SpMapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Tooltip(
                message: 'Zoom in',
                child: InkWell(
                  onTap: onZoomIn,
                  child: const SizedBox.square(
                    dimension: 44.0,
                    child: Center(child: Icon(SpIcons.zoomIn, size: 20.0)),
                  ),
                ),
              ),
              Divider(height: 1.0, color: colorScheme.outlineVariant),
              Tooltip(
                message: 'Zoom out',
                child: InkWell(
                  onTap: onZoomOut,
                  child: const SizedBox.square(
                    dimension: 44.0,
                    child: Center(child: Icon(SpIcons.zoomOut, size: 20.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
