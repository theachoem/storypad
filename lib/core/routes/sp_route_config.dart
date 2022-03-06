import 'package:flutter/material.dart';
import 'package:spooky/core/models/story_model.dart';
import 'package:spooky/core/routes/router.gr.dart';
import 'package:spooky/core/routes/setting/animated_route_setting.dart';
import 'package:spooky/core/routes/setting/base_route_setting.dart';
import 'package:spooky/core/routes/setting/default_route_setting.dart';
import 'package:spooky/core/routes/sp_router.dart';
import 'package:spooky/theme/m3/m3_color.dart';
import 'package:spooky/views/app_starter/app_starter_view.dart';
import 'package:spooky/views/archive/archive_view.dart';
import 'package:spooky/views/changes_history/changes_history_view.dart';
import 'package:spooky/views/cloud_storage/cloud_storage_view.dart';
import 'package:spooky/views/content_reader/content_reader_view.dart';
import 'package:spooky/views/detail/detail_view.dart';
import 'package:spooky/views/developer_mode/developer_mode_view.dart';
import 'package:spooky/views/explore/explore_view.dart';
import 'package:spooky/views/font_manager/font_manager_view.dart';
import 'package:spooky/views/home/home_view.dart';
import 'package:spooky/views/init_pick_color/init_pick_color_view.dart';
import 'package:spooky/views/lock/lock_view.dart';
import 'package:spooky/views/main/main_view.dart';
import 'package:spooky/views/manage_pages/manage_pages_view.dart';
import 'package:spooky/views/nickname_creator/nickname_creator_view.dart';
import 'package:spooky/views/restore/restore_view.dart';
import 'package:spooky/views/security/security_view.dart';
import 'package:spooky/views/setting/setting_view.dart';
import 'package:spooky/views/theme_setting/theme_setting_view.dart';

export 'router.gr.dart';

class SpRouteConfig {
  final RouteSettings? settings;
  final BuildContext context;

  Map<SpRouter, BaseRouteSetting> routes = {};
  SpRouteConfig({
    required this.context,
    this.settings,
  }) {
    routes.clear();
    for (SpRouter path in SpRouter.values) {
      routes[path] = _buildRoute(path);
    }
  }

  Route<dynamic> generate() {
    SpRouter router = SpRouter.notFound;

    for (SpRouter element in SpRouter.values) {
      if (settings?.name == element.path) {
        router = element;
        break;
      }
    }

    BaseRouteSetting? setting = routes[router];
    return setting!.toRoute(context, settings);
  }

  BaseRouteSetting _buildRoute(SpRouter router) {
    switch (router) {
      case SpRouter.restore:
        return DefaultRouteSetting(
          title: "Restore",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const RestoreView(),
        );
      case SpRouter.cloudStorage:
        return DefaultRouteSetting(
          title: "Cloud Storage",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const CloudStorageView(),
        );
      case SpRouter.fontManager:
        return DefaultRouteSetting(
          title: "Font Manager",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const FontManagerView(),
        );
      case SpRouter.lock:
        return DefaultRouteSetting(
          title: "Lock",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) {
            Object? arguments = settings?.arguments;
            if (arguments is LockArgs) {
              return LockView(flowType: arguments.flowType);
            }
            return buildNotFound();
          },
        );
      case SpRouter.security:
        return DefaultRouteSetting(
          title: "Security",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const SecurityView(),
        );
      case SpRouter.themeSetting:
        return DefaultRouteSetting(
          title: "Theme Setting",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const ThemeSettingView(),
        );
      case SpRouter.managePages:
        return DefaultRouteSetting(
          title: "Manage Pages",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) {
            Object? arguments = settings?.arguments;
            if (arguments is ManagePagesArgs) return ManagePagesView(content: arguments.content);
            return buildNotFound();
          },
        );
      case SpRouter.archive:
        return DefaultRouteSetting(
          title: "Archive",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const ArchiveView(),
        );
      case SpRouter.contentReader:
        return DefaultRouteSetting(
          title: "Content Reader",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) {
            Object? arguments = settings?.arguments;
            if (arguments is ContentReaderArgs) return ContentReaderView(content: arguments.content);
            return buildNotFound();
          },
        );
      case SpRouter.changesHistory:
        return DefaultRouteSetting(
          title: "Changes History",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) {
            Object? arguments = settings?.arguments;
            if (arguments is ChangesHistoryArgs) {
              return ChangesHistoryView(
                story: arguments.story,
                onRestorePressed: arguments.onRestorePressed,
                onDeletePressed: arguments.onDeletePressed,
              );
            }
            return buildNotFound();
          },
        );
      case SpRouter.detail:
        return DefaultRouteSetting<StoryModel>(
          title: "Detail",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) {
            Object? arguments = settings?.arguments;
            if (arguments is DetailArgs) {
              return DetailView(
                initialStory: arguments.initialStory,
                intialFlow: arguments.intialFlow,
              );
            }
            return buildNotFound();
          },
        );
      case SpRouter.main:
        return DefaultRouteSetting(
          title: "Main",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const MainView(),
        );
      case SpRouter.home:
        return DefaultRouteSetting(
          title: "Home",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) {
            Object? arguments = settings?.arguments;
            if (arguments is HomeArgs) {
              return HomeView(
                onTabChange: arguments.onTabChange,
                onYearChange: arguments.onYearChange,
                onListReloaderReady: arguments.onListReloaderReady,
                onScrollControllerReady: arguments.onScrollControllerReady,
              );
            }
            return buildNotFound();
          },
        );
      case SpRouter.explore:
        return DefaultRouteSetting(
          title: "Explore",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const ExploreView(),
        );
      case SpRouter.setting:
        return DefaultRouteSetting(
          title: "Setting",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const SettingView(),
        );
      case SpRouter.appStarter:
        return DefaultRouteSetting(
          title: "Setting",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const AppStarterView(),
        );
      case SpRouter.initPickColor:
        return AnimatedRouteSetting(
          title: "Pick Color",
          fullscreenDialog: true,
          fillColor: M3Color.of(context).background,
          route: (context) => const InitPickColorView(),
        );
      case SpRouter.nicknameCreator:
        return AnimatedRouteSetting(
          title: "Nickname Creator",
          fullscreenDialog: true,
          fillColor: M3Color.of(context).background,
          route: (context) => const NicknameCreatorView(),
        );
      case SpRouter.developerModeView:
        return DefaultRouteSetting(
          title: "Developer Mode",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => const DeveloperModeView(),
        );
      case SpRouter.notFound:
        return DefaultRouteSetting(
          title: "Not Found",
          canSwap: false,
          fullscreenDialog: false,
          route: (context) => buildNotFound(),
        );
    }
  }

  static Widget buildNotFound() {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text("Not found"),
      ),
    );
  }
}
