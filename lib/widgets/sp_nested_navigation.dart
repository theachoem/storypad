import 'package:flutter/material.dart';
import 'package:storypad/routes/utils/animated_page_route.dart';

// Nested navigation inside same parent. Eg. navigations in dialog.
class SpNestedNavigation extends StatefulWidget {
  const SpNestedNavigation({
    super.key,
    required this.initialScreen,
  });

  final Widget initialScreen;

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
      ),
    );
  }

  void pop<T>() {
    return navigationKey.currentState!.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: Navigator(
        key: navigationKey,
        onGenerateRoute: (setting) {
          return AnimatedPageRoute.sharedAxis(
            type: SharedAxisTransitionType.horizontal,
            builder: (context) {
              return widget.initialScreen;
            },
          );
        },
      ),
    );
  }
}
