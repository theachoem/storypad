import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/animated_route_helper.dart';

// Nested navigation inside same parent. Eg. navigations in dialog.
class SpNestedNavigation extends StatefulWidget {
  const SpNestedNavigation({
    super.key,
    required this.initialScreen,
    this.backgroundColor,
    this.transitionType = SharedAxisTransitionType.horizontal,
  });

  final Widget initialScreen;
  final Color? backgroundColor;
  final SharedAxisTransitionType transitionType;

  static SpNestedNavigationState? maybeOf(BuildContext context) {
    return context.findRootAncestorStateOfType<SpNestedNavigationState>();
  }

  static bool? canPop(BuildContext context) {
    return context.findRootAncestorStateOfType<SpNestedNavigationState>()?.navigationKey.currentState?.canPop();
  }

  @override
  State<SpNestedNavigation> createState() => SpNestedNavigationState();
}

class SpNestedNavigationState extends State<SpNestedNavigation> {
  final GlobalKey<NavigatorState> navigationKey = GlobalKey();

  Future<T?> push<T>(Widget screen) {
    return navigationKey.currentState!.push<T>(
      AnimatedRouteHelper.sharedAxis(
        type: widget.transitionType,
        builder: (context) => screen,
        fillColor: widget.backgroundColor,
      ),
    );
  }

  Future<T?> pushReplacement<T>(Widget screen) {
    return navigationKey.currentState!.pushReplacement(
      AnimatedRouteHelper.sharedAxis(
        type: widget.transitionType,
        builder: (context) => screen,
        fillColor: widget.backgroundColor,
      ),
    );
  }

  void pop<T>() {
    return navigationKey.currentState!.pop();
  }

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
      child: Navigator(
        clipBehavior: Clip.hardEdge,
        key: navigationKey,
        onGenerateRoute: (setting) {
          return AnimatedRouteHelper.sharedAxis(
            type: widget.transitionType,
            fillColor: widget.backgroundColor,
            builder: (context) {
              return widget.initialScreen;
            },
          );
        },
      ),
    );
  }
}
