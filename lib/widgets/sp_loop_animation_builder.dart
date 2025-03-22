import 'package:flutter/material.dart';

class SpLoopAnimationBuilder extends StatefulWidget {
  const SpLoopAnimationBuilder({
    super.key,
    this.duration = Durations.long1,
    this.reverseDuration = Durations.long1,
    this.child,
    this.curve = Curves.ease,
    this.reverse = true,
    this.loopCount,
    required this.builder,
  });

  final Duration duration;
  final Duration reverseDuration;
  final Widget? child;
  final Curve curve;
  final bool reverse;
  final Widget Function(BuildContext context, double value, Widget? child) builder;
  final int? loopCount;

  @override
  State<SpLoopAnimationBuilder> createState() => _SpLoopAnimationBuilderState();
}

class _SpLoopAnimationBuilderState extends State<SpLoopAnimationBuilder> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
  );

  int loopCount = 0;

  @override
  void initState() {
    super.initState();

    controller.forward();
    controller.addStatusListener((status) {
      if (widget.loopCount != null && loopCount > widget.loopCount!) {
        controller.reverse();
        return;
      }

      loopCount += 1;

      if (status == AnimationStatus.completed) {
        if (widget.reverse) {
          controller.reverse();
        } else {
          controller.forward(from: 0.0);
        }
      } else if (status == AnimationStatus.dismissed) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurveTween(curve: widget.curve).animate(controller),
      child: widget.child,
      builder: (context, child) {
        return widget.builder(context, controller.value, child);
      },
    );
  }
}
