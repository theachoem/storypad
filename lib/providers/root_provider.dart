import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'package:storypad/core/services/windowed_detector_service.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/root/local_widgets/root_view_side_bar_info.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

class RootProvider extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final String initialRoute = const HomeRoute().routeName;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<String> selectedRootRouteNameNotifier = ValueNotifier('home');
  final HeroController heroController = MaterialApp.createMaterialHeroController();

  late final ValueNotifier<RootViewSideBarInfo?> sideBarInfoNotifier;

  RootProvider(BuildContext context) {
    // Initialize sideBarInfoNotifier with implicitView width/height so on mobile, there is no sidebar flicker.
    // On desktop, implicitView can be null, so sideBarInfoNotifier stays null &
    // is set normally by the RootView LayoutBuilder, which is also the default
    // behavior when resizing the window.
    final view = PlatformDispatcher.instance.implicitView;

    if (view != null) {
      sideBarInfoNotifier = ValueNotifier(
        getSideBarInfoWith(
          view.physicalSize.width / view.devicePixelRatio,
          view.physicalSize.height / view.devicePixelRatio,
          null,
        ),
      );
    } else {
      sideBarInfoNotifier = ValueNotifier(null);
    }
  }

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

  void setSideBarInfoWithConstraints(BoxConstraints constraints) {
    debouncedCallback(duration: const Duration(milliseconds: 100), () {
      sideBarInfoNotifier.value = getSideBarInfoWith(
        constraints.maxWidth,
        constraints.maxHeight,
        sideBarInfoNotifier.value,
      );
    });
  }

  RootViewSideBarInfo? getSideBarInfoWith(double? width, double? height, RootViewSideBarInfo? oldValue) {
    if (width == null || height == null) return oldValue;

    bool bigScreen = WindowedDetectorService.isBigWindowFor(width, height);

    return RootViewSideBarInfo(
      bigScreen: bigScreen,
      colorScheme: oldValue?.colorScheme,
      temporaryHidden: oldValue?.temporaryHidden ?? false,
    );
  }

  // Allows screens with customizable backgrounds to update the sidebar icon foreground color for visibility.
  // When a page closes, reset the foreground color to null to restore the default color based on the theme.
  void setSideBarColorScheme(ColorScheme? colorScheme) {
    if (colorScheme == sideBarInfoNotifier.value?.colorScheme) return;
    sideBarInfoNotifier.value = sideBarInfoNotifier.value?.copyWithColorScheme(colorScheme);
  }

  // (optional) Used by temporary hidden sidebars to show/hide the sidebar.
  // When opening sheets or dialogs, we can optionally hide the sidebar temporarily for better focus.
  void setTemporaryHidden(bool temporaryHidden) {
    if (temporaryHidden == sideBarInfoNotifier.value?.temporaryHidden) return;
    sideBarInfoNotifier.value = sideBarInfoNotifier.value?.copyWith(temporaryHidden: temporaryHidden);
  }

  @override
  void dispose() {
    selectedRootRouteNameNotifier.dispose();
    sideBarInfoNotifier.dispose();
    heroController.dispose();
    super.dispose();
  }
}
