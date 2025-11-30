import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/root/local_widgets/root_view_side_bar_info.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/search/search_view.dart';
import 'package:storypad/views/tags/show/show_tag_view.dart';

class RootViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<String> selectedRootRouteNameNotifier = ValueNotifier('home');
  final HeroController heroController = MaterialApp.createMaterialHeroController();

  final ValueNotifier<RootViewSideBarInfo?> sideBarInfoNotifier = ValueNotifier(null);

  String? get initialRoute => 'home';

  void navigate(String routeName, BaseRoute? arguments) {
    bool alreadySelected = selectedRootRouteNameNotifier.value == routeName;

    if (routeName == 'home') {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else if (alreadySelected) {
      navigatorKey.currentState?.popUntil((route) => route.settings.name == routeName);
    } else {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName,
        (route) => route.isFirst,
        arguments: arguments,
      );
    }
  }

  MaterialPageRoute<dynamic>? generateRoute(RouteSettings settings) {
    Widget? page;

    if (settings.name == 'home') {
      page = const HomeView();
    } else if (settings.name == SearchRoute.routeName) {
      page = SearchView(params: settings.arguments as SearchRoute);
    } else if (settings.name == CalendarRoute.routeName) {
      page = CalendarView(
        params: settings.arguments as CalendarRoute,
      );
    } else if (settings.name == LibraryRoute.routeName) {
      page = LibraryView(
        params: settings.arguments as LibraryRoute,
      );
    } else if (settings.name == RelaxSoundsRoute.routeName) {
      page = RelaxSoundsView(
        params: settings.arguments as RelaxSoundsRoute,
      );
    } else if (settings.name != null && settings.name!.startsWith('tags/')) {
      page = ShowTagView(
        params: settings.arguments as ShowTagRoute,
      );
    }

    if (page == null) return null;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => page!,
    );
  }

  void setSideBarInfoWithConstraints(BoxConstraints constraints) {
    debouncedCallback(duration: const Duration(milliseconds: 100), () {
      bool bigScreen = constraints.maxWidth >= 720.0 && constraints.maxHeight >= 500.0;

      bool showSideBar;
      bool manuallyToggled;

      final oldValue = sideBarInfoNotifier.value;

      if (bigScreen) {
        manuallyToggled = oldValue?.manuallyToggled ?? false;
        showSideBar = manuallyToggled ? oldValue!.showSideBar : true;
      } else {
        manuallyToggled = false;
        showSideBar = false;
      }

      sideBarInfoNotifier.value = RootViewSideBarInfo(
        bigScreen: bigScreen,
        showSideBar: bigScreen ? showSideBar : false,
        manuallyToggled: bigScreen ? sideBarInfoNotifier.value?.manuallyToggled ?? false : false,
      );
    });
  }

  @override
  void dispose() {
    selectedRootRouteNameNotifier.dispose();
    sideBarInfoNotifier.dispose();
    heroController.dispose();
    super.dispose();
  }
}
