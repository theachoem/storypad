import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/root/local_widgets/root_view_side_bar_info.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

class RootProvider extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final String initialRoute = const HomeRoute().routeName;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<String> selectedRootRouteNameNotifier = ValueNotifier('home');
  final HeroController heroController = MaterialApp.createMaterialHeroController();

  final ValueNotifier<RootViewSideBarInfo> sideBarInfoNotifier = ValueNotifier(
    RootViewSideBarInfo(
      colorScheme: null,
      temporaryHidden: false,
    ),
  );

  /// For any navigation from sidebar, use this RootProvider#navigate instead of push directly.
  void navigate(BaseRoute route) {
    bool alreadySelected = selectedRootRouteNameNotifier.value == route.routeName;

    AnalyticsService.instance.logViewRoute(
      routeObject: route,
      analyticsParameters: route.analyticsParameters,
    );

    if (route.routeName == const HomeRoute().routeName) {
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
    } else if (alreadySelected) {
      navigatorKey.currentState?.popUntil((r) => r.settings.name == route.routeName);
    } else {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        route.routeName!,
        (r) => r.isFirst,
        arguments: route,
      );
    }
  }

  /// Builds pages based on [RouteSettings].
  /// Except the home page which is the initial route and does not require any arguments,
  /// All other pages should use [BaseRoute] as arguments for navigation.
  MaterialPageRoute<dynamic>? generateRoute(RouteSettings settings) {
    BaseRoute? route;

    if (settings.name == const HomeRoute().routeName) {
      route = const HomeRoute();
    } else if (settings.arguments is BaseRoute) {
      route = settings.arguments as BaseRoute;
    }

    if (route == null) return null;

    return MaterialPageRoute(
      settings: settings,
      builder: (context) => route!.buildPage(context),
    );
  }

  // Allows screens with customizable backgrounds to update the sidebar icon foreground color for visibility.
  // When a page closes, reset the foreground color to null to restore the default color based on the theme.
  void setSideBarColorScheme(ColorScheme? colorScheme) {
    if (colorScheme == sideBarInfoNotifier.value.colorScheme) return;
    sideBarInfoNotifier.value = sideBarInfoNotifier.value.copyWithColorScheme(colorScheme);
  }

  // (optional) Used by temporary hidden sidebars to show/hide the sidebar.
  // When opening sheets or dialogs, we can optionally hide the sidebar temporarily for better focus.
  void setTemporaryHidden(bool temporaryHidden) {
    if (temporaryHidden == sideBarInfoNotifier.value.temporaryHidden) return;
    sideBarInfoNotifier.value = sideBarInfoNotifier.value.copyWith(temporaryHidden: temporaryHidden);
  }

  @override
  void dispose() {
    selectedRootRouteNameNotifier.dispose();
    sideBarInfoNotifier.dispose();
    heroController.dispose();
    super.dispose();
  }
}
