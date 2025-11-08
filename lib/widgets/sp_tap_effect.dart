import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';

enum SpTapEffectType {
  touchableOpacity,
  scaleDown,
  border,
}

class SpTapEffectBorderOption {
  final BoxShape shape;
  final double scale;
  final double width;
  final Color color;

  SpTapEffectBorderOption({
    required this.shape,
    required this.scale,
    required this.width,
    required this.color,
  });
}

class SpTapEffect extends StatefulWidget {
  const SpTapEffect({
    super.key,
    required this.child,
    required this.onTap,
    this.duration = const Duration(milliseconds: 100),
    this.vibrate = false,
    this.behavior = HitTestBehavior.opaque,
    this.effects = const [
      SpTapEffectType.touchableOpacity,
    ],
    this.onLongPressed,
    this.borderOption,
    this.scaleActive = 0.98,
  });

  final Widget child;
  final double scaleActive;
  final SpTapEffectBorderOption? borderOption;
  final List<SpTapEffectType> effects;
  final void Function()? onTap;
  final void Function()? onLongPressed;
  final Duration duration;
  final bool vibrate;
  final HitTestBehavior? behavior;

  @override
  State<SpTapEffect> createState() => _SpTapEffectState();
}

class _SpTapEffectState extends State<SpTapEffect> with SingleTickerProviderStateMixin {
  final double opacityActive = 0.2;
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;
  late Animation<double> borderAnimation;

  @override
  void initState() {
    controller = AnimationController(vsync: this, duration: widget.duration);
    scaleAnimation = Tween<double>(begin: 1, end: widget.scaleActive).animate(controller);
    opacityAnimation = Tween<double>(begin: 1, end: opacityActive).animate(controller);
    borderAnimation = Tween<double>(begin: 0, end: 1).animate(controller);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onTap() {
    if (widget.onTap != null) widget.onTap!();
    Feedback.forTap(context);
  }

  void onTapCancel() => controller.reverse();
  void onTapDown() => controller.forward();
  void onTapUp() {
    onTap();
    controller.reverse();
  }

  void onDoubleTap() async {
    controller.forward().then((value) => controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap != null) {
      return GestureDetector(
        behavior: widget.behavior,
        onLongPress: widget.onLongPressed != null
            ? () {
                Feedback.forLongPress(context);
                widget.onLongPressed!();
              }
            : null,
        onTapDown: (detail) => onTapDown(),
        onTapUp: (detail) => onTapUp(),
        onTapCancel: () => onTapCancel(),
        child: buildChild(controller),
      );
    } else {
      return buildChild(controller);
    }
  }

  AnimatedBuilder buildChild(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        Widget result = child ?? const SizedBox();
        for (var effect in widget.effects) {
          switch (effect) {
            case SpTapEffectType.scaleDown:
              result = ScaleTransition(scale: scaleAnimation, child: result);
              break;
            case SpTapEffectType.touchableOpacity:
              result = Opacity(opacity: opacityAnimation.value, child: result);
              break;
            case SpTapEffectType.border:
              result = Stack(
                alignment: Alignment.center,
                children: [
                  result,
                  Positioned.fill(
                    child: Container(
                      transform: Matrix4.identity()..spScale(widget.borderOption?.scale ?? 1.25),
                      transformAlignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: widget.borderOption?.width ?? 2,
                          color: Color.lerp(
                            Colors.transparent,
                            widget.borderOption?.color ?? Theme.of(context).colorScheme.onSurface,
                            borderAnimation.value,
                          )!,
                        ),
                        shape: widget.borderOption?.shape ?? BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
              break;
          }
        }
        return result;
      },
      child: widget.child,
    );
  }
}
