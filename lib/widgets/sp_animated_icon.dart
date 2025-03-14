import 'package:flutter/material.dart';

class SpAnimatedIcons extends StatelessWidget {
  const SpAnimatedIcons._({
    required this.firstChild,
    required this.secondChild,
    required this.showFirst,
    required this.transitionBuilder,
    required this.switchInCurve,
    required this.switchOutCurve,
    this.duration = Durations.medium1,
    this.listener,
  });

  final Widget firstChild;
  final Widget secondChild;

  final Curve switchInCurve;
  final Curve switchOutCurve;

  final bool showFirst;
  final Duration duration;
  final void Function(Animation<double> animation)? listener;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  factory SpAnimatedIcons({
    required Widget firstChild,
    required Widget secondChild,
    required bool showFirst,
    Duration duration = Durations.medium1,
    void Function(Animation<double> animation)? listener,
  }) {
    return SpAnimatedIcons._(
      firstChild: firstChild,
      secondChild: secondChild,
      showFirst: showFirst,
      duration: duration,
      listener: listener,
      switchInCurve: Curves.fastOutSlowIn,
      switchOutCurve: Curves.easeInToLinear,
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: child.key == firstChild.key
              ? Tween<double>(begin: 0.25, end: 0).animate(animation)
              : Tween<double>(begin: 0.75, end: 1).animate(animation),
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
    );
  }

  factory SpAnimatedIcons.fadeScale({
    required Widget firstChild,
    required Widget secondChild,
    required bool showFirst,
    Duration duration = Durations.medium1,
    void Function(Animation<double> animation)? listener,
  }) {
    return SpAnimatedIcons._(
      firstChild: firstChild,
      secondChild: secondChild,
      showFirst: showFirst,
      duration: duration,
      listener: listener,
      switchInCurve: Curves.ease,
      switchOutCurve: Curves.ease,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget firstChild = this.firstChild;
    Widget secondChild = this.secondChild;

    if (firstChild.key == null) {
      firstChild = SizedBox(
        key: const ValueKey("1"),
        child: firstChild,
      );
    }
    if (secondChild.key == null) {
      secondChild = SizedBox(
        key: const ValueKey("2"),
        child: secondChild,
      );
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.fastOutSlowIn,
      switchOutCurve: Curves.easeInToLinear,
      child: showFirst ? firstChild : secondChild,
      transitionBuilder: (child, animation) {
        if (listener != null) listener!(animation);
        return transitionBuilder(child, animation);
      },
    );
  }
}
