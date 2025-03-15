import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';

abstract class BaseRoute {
  bool get preferredNestedRoute => false;

  // Only basic user unrelated info. Most screen should return empty.
  Map<String, String?>? get analyticsParameters => null;

  String get className => runtimeType.toString();

  String get analyticScreenName => className.replaceAll("Route", "");
  String get analyticScreenClass => className.replaceAll("Route", "View");

  Widget buildPage(BuildContext context);

  Future<T?> push<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) async {
    AnalyticsService.instance.logViewRoute(
      routeObject: this,
      analyticsParameters: analyticsParameters,
    );

    if (!context.mounted) return null;

    return Navigator.of(context, rootNavigator: rootNavigator).push(MaterialPageRoute(builder: (context) {
      return buildPage(context);
    }));
  }

  Future<T?> pushReplacement<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    AnalyticsService.instance.logViewRoute(
      routeObject: this,
      analyticsParameters: analyticsParameters,
    );

    return Navigator.of(context, rootNavigator: rootNavigator).pushReplacement(MaterialPageRoute(builder: (context) {
      return buildPage(context);
    }));
  }

  Future<T?> showSheet<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
    bool isScrollControlled = false,
  }) async {
    AnalyticsService.instance.logViewRoute(
      routeObject: this,
      analyticsParameters: analyticsParameters,
    );

    return showModalBottomSheet(
      useRootNavigator: rootNavigator,
      context: context,
      showDragHandle: true,
      isScrollControlled: isScrollControlled,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent),
          ),
          child: buildPage(context),
        );
      },
    );
  }
}
