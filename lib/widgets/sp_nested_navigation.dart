import 'package:flutter/material.dart';

// Nested navigation inside same parent. Eg. navigations in dialog.
class SpNestedNavigation extends StatefulWidget {
  const SpNestedNavigation({
    super.key,
    this.navigatorKey,
    required this.initialScreen,
  });

  final Key? navigatorKey;
  final Widget initialScreen;

  static SpNestedNavigationState? maybeOf(BuildContext context) {
    return context.findRootAncestorStateOfType<SpNestedNavigationState>();
  }

  @override
  State<SpNestedNavigation> createState() => SpNestedNavigationState();
}

class SpNestedNavigationState extends State<SpNestedNavigation> {
  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(
      controller: MaterialApp.createMaterialHeroController(),
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
    );
  }
}
