import 'package:flutter/material.dart';

// Nested navigation inside same parent. Eg. navigations in dialog.
class SpNestedNavigation extends StatefulWidget {
  const SpNestedNavigation({
    super.key,
    this.navigatorKey,
    required this.initialScreen,
  });

  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget initialScreen;

  static SpNestedNavigationState? maybeOf(BuildContext context) {
    return context.findRootAncestorStateOfType<SpNestedNavigationState>();
  }

  @override
  State<SpNestedNavigation> createState() => SpNestedNavigationState();
}

class SpNestedNavigationState extends State<SpNestedNavigation> {
  final HeroController heroController = MaterialApp.createMaterialHeroController();

  @override
  void dispose() {
    heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final NavigatorState? navigator = widget.navigatorKey?.currentState;
          if (navigator?.canPop() ?? false) navigator?.maybePop(result);
        }
      },
      child: HeroControllerScope(
        controller: heroController,
        child: ScaffoldMessenger(
          child: Navigator(
            key: widget.navigatorKey,
            clipBehavior: Clip.hardEdge,
            onGenerateRoute: (setting) {
              return MaterialPageRoute(
                builder: (context) {
                  return widget.initialScreen;
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
