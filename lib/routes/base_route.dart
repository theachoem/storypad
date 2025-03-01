import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics_service.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

abstract class BaseRoute {
  bool get preferredNestedRoute => false;

  // Only basic user unrelated info. Most screen should return empty.
  Map<String, String?>? get analyticsParameters => null;

  Widget buildPage(BuildContext context);

  Future<T?> pushReplacement<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: rootNavigator).pushReplacement(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return buildPage(context);
        },
      ),
    );
  }

  Future<T?> push<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    AnalyticsService.instance.logViewRoute(
      routeObject: this,
      analyticsParameters: analyticsParameters,
    );

    final router = preferredNestedRoute ? SpNestedNavigation.maybeOf(context) : null;
    if (router != null) {
      return router.push(buildPage(context));
    } else {
      return Navigator.of(context, rootNavigator: rootNavigator).push(MaterialPageRoute(builder: (context) {
        return buildPage(context);
      }));
    }
  }
}
