import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';

class SpFadeIn extends StatelessWidget {
  const SpFadeIn({
    super.key,
    required this.child,
    this.duration = Durations.medium1,
    this.curve = Curves.ease,
    this.builder,
    this.delay,
    this.onFadeIn,
    this.onCustomControllerLoaded,
    bool testCurves = false,
  }) : testCurves = kDebugMode && testCurves;

  final bool testCurves;
  final Widget child;
  final Curve curve;
  final Duration? delay;
  final Duration duration;
  final void Function()? onFadeIn;
  final void Function(AnimationController controller)? onCustomControllerLoaded;
  final Widget Function(BuildContext context, Animation<double> animation, Widget child)? builder;

  factory SpFadeIn.fromLeft({
    required Widget child,
    Duration? delay,
    Duration duration = Durations.medium1,
    bool testCurves = false,
  }) {
    return SpFadeIn(
      delay: delay,
      duration: duration,
      testCurves: testCurves,
      builder: (context, animation, child) {
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()..spTranslate(lerpDouble(-4.0, 0, animation.value)!, 0.0),
                child: child,
              );
            },
          ),
        );
      },
      child: child,
    );
  }

  factory SpFadeIn.fromRight({
    required Widget child,
    Duration? delay,
    Duration duration = Durations.medium1,
    bool testCurves = false,
  }) {
    return SpFadeIn(
      delay: delay,
      duration: duration,
      testCurves: testCurves,
      builder: (context, animation, child) {
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()..spTranslate(lerpDouble(4.0, 0, animation.value)!, 0.0),
                child: child,
              );
            },
          ),
        );
      },
      child: child,
    );
  }

  factory SpFadeIn.fromTop({
    required Widget child,
    Duration? delay,
    Duration duration = Durations.medium1,
    bool testCurves = false,
  }) {
    return SpFadeIn(
      delay: delay,
      duration: duration,
      testCurves: testCurves,
      builder: (context, animation, child) {
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()..spTranslate(0.0, lerpDouble(-4.0, 0, animation.value)!),
                child: child,
              );
            },
          ),
        );
      },
      child: child,
    );
  }

  factory SpFadeIn.fromBottom({
    required Widget child,
    Duration? delay,
    Duration duration = Durations.medium1,
    bool testCurves = false,
    void Function()? onFadeIn,
  }) {
    return SpFadeIn(
      delay: delay,
      duration: duration,
      testCurves: testCurves,
      onFadeIn: onFadeIn,
      builder: (context, animation, child) {
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.identity()..spTranslate(0.0, lerpDouble(4.0, 0, animation.value)!),
                child: child,
              );
            },
          ),
        );
      },
      child: child,
    );
  }

  factory SpFadeIn.bound({
    required Widget child,
    Duration? delay,
    Duration duration = Durations.medium1,
    bool testCurves = false,
  }) {
    return SpFadeIn(
      delay: delay,
      duration: duration,
      testCurves: testCurves,
      builder: (context, animation, child) {
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              return AnimatedContainer(
                duration: Durations.medium1,
                transform: Matrix4.identity()..spScale(animation.value > 0.2 ? 1.0 : 0.9),
                transformAlignment: Alignment.center,
                curve: Curves.ease,
                child: child,
              );
            },
          ),
        );
      },
      child: child,
    );
  }

  factory SpFadeIn.rotate({
    required Widget child,
    Duration? delay,
    Duration duration = Durations.medium1,
    bool testCurves = false,
  }) {
    return SpFadeIn(
      delay: delay,
      duration: duration,
      testCurves: testCurves,
      builder: (context, animation, child) {
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              return Transform(
                transform: Matrix4.rotationZ(lerpDouble(-1, 0, animation.value)!),
                alignment: Alignment.center,
                child: child,
              );
            },
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return child;
    if (delay != null) {
      return FutureBuilder<int>(
        future: Future.delayed(delay!).then((value) => 1),
        builder: (context, snapshot) {
          return Visibility(
            visible: snapshot.data == 1,
            child: buildAnimatedChild(),
          );
        },
      );
    } else {
      return buildAnimatedChild();
    }
  }

  Widget buildAnimatedChild() {
    return _AnimationState(
      duration: duration,
      curve: curve,
      testCurves: testCurves,
      onFadeIn: onFadeIn,
      onCustomControllerLoaded: onCustomControllerLoaded,
      builder: (context, animation) {
        return builder != null
            ? builder!(context, animation, child)
            : FadeTransition(
                opacity: animation,
                child: child,
              );
      },
    );
  }
}

class _AnimationState extends StatefulWidget {
  const _AnimationState({
    required this.duration,
    required this.curve,
    required this.builder,
    required this.onFadeIn,
    required this.testCurves,
    required this.onCustomControllerLoaded,
  });

  final bool testCurves;
  final Duration duration;
  final Curve curve;
  final void Function()? onFadeIn;
  final Widget Function(BuildContext context, Animation<double> animation) builder;

  // manully controll the animation
  final void Function(AnimationController controller)? onCustomControllerLoaded;

  @override
  State<_AnimationState> createState() => __AnimationStateState();
}

class __AnimationStateState extends State<_AnimationState> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  String? debugCurveName;
  late Curve curve = widget.curve;

  final curves = {
    'linear': Curves.linear,
    'decelerate': Curves.decelerate,
    'fastLinearToSlowEaseIn': Curves.fastLinearToSlowEaseIn,
    'fastEaseInToSlowEaseOut': Curves.fastEaseInToSlowEaseOut,
    'ease': Curves.ease,
    'easeIn': Curves.easeIn,
    'easeInToLinear': Curves.easeInToLinear,
    'easeInSine': Curves.easeInSine,
    'easeInQuad': Curves.easeInQuad,
    'easeInCubic': Curves.easeInCubic,
    'easeInQuart': Curves.easeInQuart,
    'easeInQuint': Curves.easeInQuint,
    'easeInExpo': Curves.easeInExpo,
    'easeInCirc': Curves.easeInCirc,
    'easeInBack': Curves.easeInBack,
    'easeOut': Curves.easeOut,
    'linearToEaseOut': Curves.linearToEaseOut,
    'easeOutSine': Curves.easeOutSine,
    'easeOutQuad': Curves.easeOutQuad,
    'easeOutCubic': Curves.easeOutCubic,
    'easeOutQuart': Curves.easeOutQuart,
    'easeOutQuint': Curves.easeOutQuint,
    'easeOutExpo': Curves.easeOutExpo,
    'easeOutCirc': Curves.easeOutCirc,
    'easeOutBack': Curves.easeOutBack,
    'easeInOut': Curves.easeInOut,
    'easeInOutSine': Curves.easeInOutSine,
    'easeInOutQuad': Curves.easeInOutQuad,
    'easeInOutCubic': Curves.easeInOutCubic,
    'easeInOutCubicEmphasized': Curves.easeInOutCubicEmphasized,
    'easeInOutQuart': Curves.easeInOutQuart,
    'easeInOutQuint': Curves.easeInOutQuint,
    'easeInOutExpo': Curves.easeInOutExpo,
    'easeInOutCirc': Curves.easeInOutCirc,
    'easeInOutBack': Curves.easeInOutBack,
    'fastOutSlowIn': Curves.fastOutSlowIn,
    'slowMiddle': Curves.slowMiddle,
    'bounceIn': Curves.bounceIn,
    'bounceOut': Curves.bounceOut,
    'bounceInOut': Curves.bounceInOut,
    'elasticIn': Curves.elasticIn,
    'elasticOut': Curves.elasticOut,
    'elasticInOut': Curves.elasticInOut,
  };

  @override
  void initState() {
    controller = AnimationController(vsync: this, duration: widget.duration);
    super.initState();

    testCurves();
  }

  void testCurves() async {
    if (widget.testCurves) {
      for (var entry in curves.entries) {
        debugCurveName = entry.key;
        curve = entry.value;
        setState(() {});

        debugPrint("TestingCurve: $debugCurveName");
        await controller.forward(from: 0.0);
        await Future.delayed(Durations.short2);
      }
    } else {
      if (widget.onCustomControllerLoaded != null) {
        widget.onCustomControllerLoaded!(controller);
      } else {
        controller.forward().then((e) {
          widget.onFadeIn?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.testCurves) {
      return Stack(
        children: [
          widget.builder(
            context,
            controller.drive(CurveTween(curve: curve)),
          ),
          Text(
            debugCurveName ?? 'N/A',
            style: TextTheme.of(context).bodyMedium,
          ),
        ],
      );
    } else {
      return widget.builder(
        context,
        controller.drive(CurveTween(curve: curve)),
      );
    }
  }
}
