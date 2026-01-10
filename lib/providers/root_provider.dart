import 'package:flutter/foundation.dart';
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
  late final ValueNotifier<RootViewSideBarInfo?> sideBarInfoNotifier;

  RootProvider(BuildContext context) {
    sideBarInfoNotifier = ValueNotifier(
      getSideBarInfoWith(
        PlatformDispatcher.instance.views.firstOrNull?.physicalSize.width,
        PlatformDispatcher.instance.views.firstOrNull?.physicalSize.height,
        null,
      ),
    );
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
      )?.copyWith(optionsExpanded: false);
    });
  }

  RootViewSideBarInfo? getSideBarInfoWith(double? width, double? height, RootViewSideBarInfo? oldValue) {
    if (width == null || height == null) return oldValue;

    bool bigScreen = width >= 720.0 && height >= 500.0;

    bool showSideBar = oldValue?.showSideBar ?? false;
    bool manuallyToggled = oldValue?.manuallyToggled ?? false;

    if (manuallyToggled) {
      // when manually toggled, but screen is now small,
      // we have to close the sidebar & reset manuallyToggled to false
      if (!bigScreen && showSideBar) {
        manuallyToggled = false;
        showSideBar = false;
      }
    } else {
      showSideBar = bigScreen ? true : false;
    }

    return RootViewSideBarInfo(
      bigScreen: bigScreen,
      showSideBar: showSideBar,
      manuallyToggled: manuallyToggled,
      optionsExpanded: oldValue?.optionsExpanded ?? false,
    );
  }

  @override
  void dispose() {
    selectedRootRouteNameNotifier.dispose();
    sideBarInfoNotifier.dispose();
    heroController.dispose();
    super.dispose();
  }
}
