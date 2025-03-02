import 'package:flutter/material.dart';
import 'package:storypad/routes/utils/animated_page_route.dart';

// Nested navigation inside same parent. Eg. navigations in dialog.
class SpNestedNavigation extends StatefulWidget {
  const SpNestedNavigation({
    super.key,
    required this.initialScreen,
    this.backgroundColor,
  });

  final Widget initialScreen;
  final Color? backgroundColor;

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
      AnimatedPageRoute.sharedAxis(
        type: SharedAxisTransitionType.horizontal,
        builder: (context) => screen,
        fillColor: widget.backgroundColor,
      ),
    );
  }

  Future<T?> pushReplacement<T>(Widget screen) {
    return navigationKey.currentState!.pushReplacement(
      AnimatedPageRoute.sharedAxis(
        type: SharedAxisTransitionType.horizontal,
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
    return Navigator(
      clipBehavior: Clip.hardEdge,
      key: navigationKey,
      onGenerateRoute: (setting) {
        return AnimatedPageRoute.sharedAxis(
          type: SharedAxisTransitionType.horizontal,
          fillColor: widget.backgroundColor,
          builder: (context) {
            return widget.initialScreen;
          },
        );
      },
    );
  }
}
