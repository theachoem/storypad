part of '../home_quick_actions_view.dart';

class _Preview extends StatelessWidget {
  const _Preview({required this.viewModel});

  final HomeQuickActionsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final menuColor = kIsCupertino ? colorScheme.surface.withValues(alpha: 0.92) : colorScheme.surface;
    const pointerHeight = 12.0;
    const pointerHalfWidth = 14.0;
    const pointerCornerRadius = 5.0;
    const menuRadius = kIsCupertino ? 14.0 : 18.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16).add(
        EdgeInsets.only(
          left: MediaQuery.paddingOf(context).left,
          right: MediaQuery.paddingOf(context).right,
        ),
      ),
      decoration: BoxDecoration(
        color: colorScheme.readOnly.surface1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: CustomPaint(
                painter: _QuickActionsBubblePainter(
                  fillColor: menuColor,
                  borderColor: colorScheme.outlineVariant,
                  radius: menuRadius,
                  pointerHeight: pointerHeight,
                  pointerHalfWidth: pointerHalfWidth,
                  pointerCornerRadius: pointerCornerRadius,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                ),
                child: ClipPath(
                  clipper: const _QuickActionsBubbleClipper(
                    radius: menuRadius,
                    pointerHeight: pointerHeight,
                    pointerHalfWidth: pointerHalfWidth,
                    pointerCornerRadius: pointerCornerRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: pointerHeight),
                    child: viewModel.visibleEnabledActions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                            child: Text(tr('page.home_quick_actions.empty_message')),
                          )
                        : ReorderableListView(
                            shrinkWrap: true,
                            buildDefaultDragHandles: false,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            onReorder: viewModel.reorderActions,
                            children: [
                              for (int i = 0; i < viewModel.visibleEnabledActions.length; i++)
                                ReorderableDelayedDragStartListener(
                                  key: ValueKey(viewModel.visibleEnabledActions[i].key),
                                  index: i,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PreviewRow(
                                        action: viewModel.visibleEnabledActions[i],
                                        activating: viewModel.isActivating(viewModel.visibleEnabledActions[i].key),
                                        onRemove: () => viewModel.removeAction(viewModel.visibleEnabledActions[i]),
                                      ),
                                      if (i < viewModel.visibleEnabledActions.length - 1) const Divider(height: 1),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: kAppLogo!.asset.image(width: 64, height: 64),
          ),
          const SizedBox(height: 8),
          Text(kAppName, style: TextTheme.of(context).labelMedium),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.action,
    required this.activating,
    required this.onRemove,
  });

  final HomeQuickActionItem action;
  final bool activating;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Durations.medium2,
      curve: Curves.ease,
      color: activating ? ColorScheme.of(context).primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
        leading: Icon(action.icon, size: 20),
        title: Text(
          action.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextTheme.of(context).bodyMedium,
        ),
        trailing: AnimatedSwitcher(
          duration: Durations.short4,
          switchInCurve: Curves.ease,
          switchOutCurve: Curves.ease,
          child: activating
              ? const SizedBox(
                  key: ValueKey('activating'),
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  key: const ValueKey('remove'),
                  tooltip: tr('button.remove_args', namedArgs: {'RM_LABEL': action.label}),
                  icon: const Icon(SpIcons.clear),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  onPressed: onRemove,
                ),
        ),
      ),
    );
  }
}

class _QuickActionsBubblePainter extends CustomPainter {
  const _QuickActionsBubblePainter({
    required this.fillColor,
    required this.borderColor,
    required this.radius,
    required this.pointerHeight,
    required this.pointerHalfWidth,
    required this.pointerCornerRadius,
    required this.shadowColor,
  });

  final Color fillColor;
  final Color borderColor;
  final double radius;
  final double pointerHeight;
  final double pointerHalfWidth;
  final double pointerCornerRadius;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildQuickActionsBubblePath(
      size,
      radius: radius,
      pointerHeight: pointerHeight,
      pointerHalfWidth: pointerHalfWidth,
      pointerCornerRadius: pointerCornerRadius,
    );

    canvas.drawShadow(path, shadowColor, 8, false);
    canvas.drawPath(path, Paint()..color = fillColor);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _QuickActionsBubblePainter oldDelegate) {
    return fillColor != oldDelegate.fillColor ||
        borderColor != oldDelegate.borderColor ||
        radius != oldDelegate.radius ||
        pointerHeight != oldDelegate.pointerHeight ||
        pointerHalfWidth != oldDelegate.pointerHalfWidth ||
        pointerCornerRadius != oldDelegate.pointerCornerRadius ||
        shadowColor != oldDelegate.shadowColor;
  }
}

class _QuickActionsBubbleClipper extends CustomClipper<Path> {
  const _QuickActionsBubbleClipper({
    required this.radius,
    required this.pointerHeight,
    required this.pointerHalfWidth,
    required this.pointerCornerRadius,
  });

  final double radius;
  final double pointerHeight;
  final double pointerHalfWidth;
  final double pointerCornerRadius;

  @override
  Path getClip(Size size) {
    return _buildQuickActionsBubblePath(
      size,
      radius: radius,
      pointerHeight: pointerHeight,
      pointerHalfWidth: pointerHalfWidth,
      pointerCornerRadius: pointerCornerRadius,
    );
  }

  @override
  bool shouldReclip(covariant _QuickActionsBubbleClipper oldClipper) {
    return radius != oldClipper.radius ||
        pointerHeight != oldClipper.pointerHeight ||
        pointerHalfWidth != oldClipper.pointerHalfWidth ||
        pointerCornerRadius != oldClipper.pointerCornerRadius;
  }
}

Path _buildQuickActionsBubblePath(
  Size size, {
  required double radius,
  required double pointerHeight,
  required double pointerHalfWidth,
  required double pointerCornerRadius,
}) {
  final width = size.width;
  final rectBottom = size.height - pointerHeight;
  final centerX = width / 2;
  final leftPointer = centerX - pointerHalfWidth;
  final rightPointer = centerX + pointerHalfWidth;
  final pointerControl = pointerHalfWidth * 0.55;

  final path = Path()
    ..moveTo(radius, 0)
    ..lineTo(width - radius, 0)
    ..arcToPoint(Offset(width, radius), radius: Radius.circular(radius))
    ..lineTo(width, rectBottom - radius)
    ..arcToPoint(Offset(width - radius, rectBottom), radius: Radius.circular(radius))
    ..lineTo(rightPointer, rectBottom)
    ..quadraticBezierTo(
      centerX + pointerControl,
      rectBottom,
      centerX + pointerCornerRadius,
      rectBottom + pointerCornerRadius,
    )
    ..quadraticBezierTo(centerX, size.height, centerX - pointerCornerRadius, rectBottom + pointerCornerRadius)
    ..quadraticBezierTo(centerX - pointerControl, rectBottom, leftPointer, rectBottom)
    ..lineTo(radius, rectBottom)
    ..arcToPoint(Offset(0, rectBottom - radius), radius: Radius.circular(radius))
    ..lineTo(0, radius)
    ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
    ..close();

  return path;
}
