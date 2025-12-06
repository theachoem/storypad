import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/bottom_sheets/sp_cupertino_full_page_sheet_configurations.dart';
import 'package:storypad/widgets/sp_nested_navigation.dart';

abstract class BaseRoute {
  const BaseRoute();

  // Only basic user unrelated info. Most screen should return empty.
  Map<String, String?>? get analyticsParameters => null;

  /// Optional route name for named navigation. Determines how the route is built and transitioned.
  ///
  /// When [routeName] is provided:
  /// - Route is generated via [RootViewModel.generateRoute()], which uses standard [MaterialPageRoute]
  /// - Ensures consistent route transitions across the app (important for root sidebar stability)
  /// - Custom route definitions in this class are ignored
  ///
  /// When [routeName] is null:
  /// - Route is built using the custom [buildRoute()] method defined in this class
  /// - Allows full customization: CupertinoSheetRoute, PageRouteBuilder with animations, etc.
  /// - Each route can define its own unique transition behavior
  String? get routeName => null;

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

    // - When a SpNestedNavigation exists: use push() so the tag view is stacked locally and the sidebar selection is preserved.
    // - When no SpNestedNavigation exists and routeName is null: use push() directly as well.
    // - else: use pushNamed() on the [RootView] navigator so the sidebar updates (tag becomes the active selection).
    final nestedNavigator = SpNestedNavigation.maybeOf(context);

    if (nestedNavigator != null || routeName == null) {
      return Navigator.of(context, rootNavigator: rootNavigator).push(buildRoute<T>(context));
    } else {
      return Navigator.of(context, rootNavigator: rootNavigator).pushNamed(routeName!, arguments: this);
    }
  }

  Future<T?> pushReplacement<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    AnalyticsService.instance.logViewRoute(
      routeObject: this,
      analyticsParameters: analyticsParameters,
    );

    // - When a SpNestedNavigation exists: use pushReplacement() so the tag view is stacked locally and the sidebar selection is preserved.
    // - When no SpNestedNavigation exists and routeName is null: use pushReplacement() directly as well.
    // - else: use pushReplacementNamed() on the [RootView] navigator so the sidebar updates (tag becomes the active selection).
    final nestedNavigator = SpNestedNavigation.maybeOf(context);

    if (nestedNavigator != null || routeName == null) {
      return Navigator.of(context, rootNavigator: rootNavigator).pushReplacement(buildRoute<T>(context));
    } else {
      return Navigator.of(context, rootNavigator: rootNavigator).pushReplacementNamed(routeName!, arguments: this);
    }
  }

  PageRoute<T> buildRoute<T>(BuildContext context) {
    return CupertinoSheetRoute.hasParentSheet(context)
        ? buildCupertinoRoute(context: context, fullscreenDialog: false)
        : buildMaterialRoute(context: context, fullscreenDialog: false);
  }

  PageRoute<T> buildCupertinoRoute<T>({
    required BuildContext context,
    required bool fullscreenDialog,
  }) {
    return CupertinoSheetRoute<T>(
      builder: (context) => SpCupertinoFullPageSheetConfigurations(context: context, child: buildPage(context)),
    );
  }

  PageRoute<T> buildMaterialRoute<T>({
    required BuildContext context,
    required bool fullscreenDialog,
  }) {
    if (fullscreenDialog) {
      return PageRouteBuilder(
        fullscreenDialog: fullscreenDialog,
        pageBuilder: (context, animation, secondaryAnimation) => buildPage(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
            child: child,
          );
        },
      );
    }

    return MaterialPageRoute<T>(
      fullscreenDialog: fullscreenDialog,
      builder: (context) => buildPage(context),
    );
  }
}
