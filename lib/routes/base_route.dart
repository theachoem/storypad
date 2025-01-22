import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

abstract class BaseRoute {
  bool get nestedRoute => false;

  Widget buildPage(BuildContext context);

  Future<T?> push<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    if (nestedRoute) {
      return SpNestedNavigation.maybeOf(context)!.push(buildPage(context));
    } else {
      return Navigator.of(context, rootNavigator: rootNavigator).push(MaterialPageRoute(builder: (context) {
        return buildPage(context);
      }));
    }
  }
}
