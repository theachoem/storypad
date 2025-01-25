import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

abstract class BaseRoute {
  bool get nestedRoute => false;

  // Only basic user unrelated info. Most screen should return empty.
  Map<String, String?>? get analyticsParameters => null;

  Widget buildPage(BuildContext context);

  Future<T?> push<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    AnalyticsService.instance.logViewRoute(
      routeObject: this,
      analyticsParameters: analyticsParameters,
    );

    if (nestedRoute) {
      return SpNestedNavigation.maybeOf(context)!.push(buildPage(context));
    } else {
      return Navigator.of(context, rootNavigator: rootNavigator).push(MaterialPageRoute(builder: (context) {
        return buildPage(context);
      }));
    }
  }
}
