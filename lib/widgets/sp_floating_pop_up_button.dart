import 'dart:async';
import 'dart:math';

import 'package:animated_clipper/animated_clipper.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_measure_size.dart';

class SpFloatingPopUpButton extends StatefulWidget {
  const SpFloatingPopUpButton({
    super.key,
    required this.builder,
    required this.floatingBuilder,
    required this.dyGetter,
    required this.estimatedFloatingWidth,
    this.bottomToTop = true,
    this.margin = 8,
    this.pathBuilder = PathBuilders.circleOut,
  });

  final double Function(double dy)? dyGetter;
  final Widget Function(VoidCallback open) builder;
  final Widget Function(FutureOr<void> Function() close) floatingBuilder;
  final double estimatedFloatingWidth;
  final double margin;
  final bool bottomToTop;
  final PathBuilder pathBuilder;

  @override
  State<SpFloatingPopUpButton> createState() => _SpFloatingPopUpButtonState();
}

class _SpFloatingPopUpButtonState extends State<SpFloatingPopUpButton> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  Size? actualFloatingSize;
  OverlayEntry? floating;

  Future<void> toggle(BuildContext context) async {
    if (!mounted) return;
    if (animationController.isAnimating) return;

    if (animationController.isCompleted) {
      await animationController.reverse();
      floating?.remove();
    } else {
      floating = createFloating(context: context);
      if (floating == null) return;

      Overlay.maybeOf(context)?.insert(floating!);
      await animationController.forward();
    }
  }

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: Durations.medium1);
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    if (animationController.isCompleted) floating?.remove();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(() => toggle(context));
  }

  OverlayEntry? createFloating({
    required BuildContext context,
  }) {
    if (!context.mounted) return null;

    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return null;

    Offset offset = renderBox.localToGlobal(Offset.zero);
    double childWidth = actualFloatingSize?.width ?? widget.estimatedFloatingWidth - 36;

    return OverlayEntry(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            double? left = offset.dx - childWidth / 2;
            double? right = constraints.maxWidth - left - childWidth;

            double? top = widget.dyGetter != null ? widget.dyGetter!(offset.dy) : offset.dy;
            double bottom = 0;

            // make sure it 8 pixel inside view.
            left = max(left, widget.margin + MediaQuery.of(context).padding.left);
            right = max(right, widget.margin + MediaQuery.of(context).padding.right);

            if (offset.dx >= constraints.maxWidth / 2) {
              left = null;
            } else {
              right = null;
            }

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => toggle(context),
              child: Stack(
                children: [
                  Positioned(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    child: SpMeasureSize(
                      onChange: (Size size) => actualFloatingSize = size,
                      child: AnimatedBuilder(
                        animation: animationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0.0,
                              (1 - animationController.value) * (widget.bottomToTop ? 8 : -8),
                            ),
                            child: Opacity(
                              opacity: animationController.value,
                              child: child,
                            ),
                          );
                        },
                        child: AnimatedClipReveal(
                          revealFirstChild: true,
                          duration: Durations.medium1,
                          curve: Curves.linear,
                          pathBuilder: widget.pathBuilder,
                          child: widget.floatingBuilder(() => toggle(context)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
