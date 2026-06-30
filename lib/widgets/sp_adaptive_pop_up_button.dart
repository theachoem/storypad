import 'dart:async';

import 'package:animated_clipper/animated_clipper.dart';
import 'package:flutter/material.dart';

/// A floating pop-up button that opens its [floatingBuilder] above or below the
/// trigger depending on which side has more room.
///
/// The pop-up follows the trigger via a [LayerLink], so it stays attached even
/// when the background scrolls or the trigger otherwise moves. Centering is
/// anchor-based ([CompositedTransformFollower]), so no size measurement is
/// needed.
class SpAdaptivePopUpButton extends StatefulWidget {
  const SpAdaptivePopUpButton({
    super.key,
    required this.builder,
    required this.floatingBuilder,
    this.gap = 8,
    this.pathBuilder = PathBuilders.circleOut,
  });

  final Widget Function(VoidCallback open) builder;

  /// Builds the floating content. [openAbove] tells the content which way the
  /// pop-up is opening so it can flip its own internal alignment if needed.
  final Widget Function(FutureOr<void> Function() close, bool openAbove) floatingBuilder;

  /// Gap between the trigger and the floating content.
  final double gap;

  final PathBuilder pathBuilder;

  @override
  State<SpAdaptivePopUpButton> createState() => _SpAdaptivePopUpButtonState();
}

class _SpAdaptivePopUpButtonState extends State<SpAdaptivePopUpButton> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  final LayerLink layerLink = LayerLink();
  OverlayEntry? floating;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this, duration: Durations.medium1);
  }

  @override
  void dispose() {
    if (animationController.isCompleted) floating?.remove();
    animationController.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (!mounted) return;
    if (animationController.isAnimating) return;

    if (animationController.isCompleted) {
      await animationController.reverse();
      floating?.remove();
      floating = null;
    } else {
      final entry = createFloating();
      if (entry == null) return;

      floating = entry;
      Overlay.maybeOf(context)?.insert(entry);
      await animationController.forward();
    }
  }

  OverlayEntry? createFloating() {
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return null;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size triggerSize = renderBox.size;

    final media = MediaQuery.of(context);
    final double spaceBelow = media.size.height - media.padding.bottom - (offset.dy + triggerSize.height);
    final double spaceAbove = offset.dy - media.padding.top;

    // Open on whichever side has more room. Decided once at open time so the
    // pop-up keeps its side while it follows the trigger around.
    final bool openAbove = spaceAbove > spaceBelow;

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => toggle(),
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                // Pin the follower's edge to the trigger's opposite edge and
                // center horizontally; the follower sizes to the content.
                targetAnchor: openAbove ? Alignment.topCenter : Alignment.bottomCenter,
                followerAnchor: openAbove ? Alignment.bottomCenter : Alignment.topCenter,
                offset: Offset(0.0, openAbove ? -widget.gap : widget.gap),
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0.0, (1 - animationController.value) * (openAbove ? -8 : 8)),
                      child: Opacity(
                        opacity: animationController.value,
                        child: child,
                      ),
                    );
                  },
                  // The follower passes loose, screen-width constraints; wrap in
                  // IntrinsicWidth so the content sizes to its natural width
                  // instead of expanding to fill the screen.
                  child: IntrinsicWidth(
                    child: AnimatedClipReveal(
                      revealFirstChild: true,
                      duration: Durations.medium1,
                      curve: Curves.linear,
                      pathBuilder: widget.pathBuilder,
                      child: widget.floatingBuilder(() => toggle(), openAbove),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: widget.builder(() => toggle()),
    );
  }
}
