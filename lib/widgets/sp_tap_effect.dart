import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.curve = Curves.ease,
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
  final Curve curve;
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
  late FocusNode _internalFocusNode;

  @override
  void initState() {
    controller = AnimationController(vsync: this, duration: widget.duration);
    scaleAnimation = Tween<double>(begin: 1, end: widget.scaleActive).animate(
      CurvedAnimation(parent: controller, curve: widget.curve),
    );
    opacityAnimation = Tween<double>(begin: 1, end: opacityActive).animate(
      CurvedAnimation(parent: controller, curve: widget.curve),
    );
    borderAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: widget.curve),
    );
    _internalFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    _internalFocusNode.dispose();
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
    Widget result;

    if (widget.onTap != null) {
      result = GestureDetector(
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
      result = buildChild(controller);
    }

    // Handle mouse hover events like InkWell.
    result = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: result,
    );

    // Handle keyboard events for accessibility.
    // Same behaviour to inkwell.
    return Focus(
      focusNode: _internalFocusNode,
      onKeyEvent: (node, event) {
        if (widget.onTap != null &&
            (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.enter) ||
                HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space))) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        if (hasFocus && widget.onTap != null) {
          controller.forward();
        } else {
          controller.reverse();
        }
      },
      child: result,
    );
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
