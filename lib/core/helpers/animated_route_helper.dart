import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
export 'package:animations/src/shared_axis_transition.dart';

class AnimatedRouteHelper {
  static Route<T> fadeThrough<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    Color? fillColor,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      settings: settings,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          fillColor: fillColor,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }

  static Route<T> fadeScale<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeScaleTransition(animation: animation, child: child);
      },
    );
  }

  static Route<T> sharedAxis<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    Color? fillColor,
    bool maintainState = true,
    bool fullscreenDialog = false,
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) {
    return PageRouteBuilder<T>(
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          fillColor: fillColor,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          child: child,
        );
      },
    );
  }
}
