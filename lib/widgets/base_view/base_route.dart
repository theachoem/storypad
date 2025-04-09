import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/widgets/bottom_sheets/sp_cupertino_full_page_sheet_configurations.dart';

abstract class BaseRoute {
  const BaseRoute();

  // Only basic user unrelated info. Most screen should return empty.
  Map<String, String?>? get analyticsParameters => null;

  String get className => runtimeType.toString();

  String get analyticScreenName => className.replaceAll("Route", "");
  String get analyticScreenClass => className.replaceAll("Route", "View");

  bool get fullscreenDialog => false;

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
    return Navigator.of(context, rootNavigator: rootNavigator).push(buildRoute<T>(context));
  }

  Future<T?> pushReplacement<T extends Object?>(
    BuildContext context, {
    bool rootNavigator = false,
  }) {
    AnalyticsService.instance.logViewRoute(
      routeObject: this,
      analyticsParameters: analyticsParameters,
    );

    return Navigator.of(context, rootNavigator: rootNavigator).pushReplacement(buildRoute<T>(context));
  }

  PageRoute<T> buildRoute<T>(BuildContext context) {
    if (fullscreenDialog) {
      return kIsCupertino
          ? CupertinoSheetRoute<T>(builder: (_) => SpCupertinoFullPageSheetConfigurations(child: buildPage(context)))
          : MaterialPageRoute<T>(builder: (context) => buildPage(context), fullscreenDialog: true);
    } else {
      return CupertinoSheetRoute.hasParentSheet(context)
          ? CupertinoSheetRoute<T>(builder: (_) => SpCupertinoFullPageSheetConfigurations(child: buildPage(context)))
          : MaterialPageRoute<T>(builder: (context) => buildPage(context));
    }
  }
}
