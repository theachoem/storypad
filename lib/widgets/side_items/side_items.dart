import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/services/app_store_opener_service.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/providers/tags_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/archives/archives_view.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/community/community_view.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/survey_banner.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_app_bottom_sheet.dart';
import 'package:storypad/widgets/side_items/local_widgets/backup_tile.dart';
import 'package:storypad/widgets/side_items/local_widgets/home_year_switcher_header.dart';
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/rewards/rewards_view.dart';
import 'package:storypad/views/search/search_view.dart';
import 'package:storypad/views/settings/settings_view.dart';
import 'package:storypad/views/tags/show/show_tag_view.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_gift_animated_icon.dart';
import 'package:storypad/widgets/sp_icons.dart';

part 'local_widgets/tag_header.dart';
part 'base_side_item.dart';
part 'side_item.dart';

const double _leadingPaddedSize = 12.0;

class SideItems {
  static void navigate({
    required bool fromSideBar,
    required BuildContext context,
    required BaseRoute route,
  }) {
    if (fromSideBar) {
      context.read<RootProvider>().navigate(route);
    } else {
      route.push(context);
    }
  }

  static List<BaseSideItem> getMainItems({
    bool fromSideBar = false,
    bool fromEndDrawer = false,
  }) {
    return [
      if (fromEndDrawer) ...[
        SideItem.custom(builder: (context) => const SurveyBanner()),
        SideItem.custom(builder: (context) => const HomeYearSwitcherHeader()),
        SideItem.divider(),
      ],
      if (fromSideBar) ...[
        SideItem(
          route: const HomeRoute(),
          title: tr('page.home.title'),
          subtitle: null,
          icon: const Icon(SpIcons.home),
        ),
        SideItem(
          route: SearchRoute(),
          title: tr('page.search.title'),
          subtitle: null,
          icon: const Icon(SpIcons.search),
        ),
        SideItem(
          route: CalendarRoute(
            initialMonth: DateTime.now().month,
            initialYear: DateTime.now().year,
            initialSegment: .mood,
          ),
          title: tr('page.calendar.title'),
          subtitle: null,
          icon: const Icon(SpIcons.calendar),
        ),
      ],
      if (fromEndDrawer)
        SideItem(
          visibleOnBigScreen: false,
          route: TagsRoute(),
          title: tr('page.tags.title'),
          subtitle: null,
          icon: const Icon(SpIcons.tag),
        ),
      SideItem(
        visibleOnBigScreen: false,
        route: LibraryRoute(),
        title: tr('page.library.title'),
        subtitle: null,
        icon: const Icon(SpIcons.photo),
      ),
      if (fromSideBar && kIAPEnabled)
        SideItem(
          route: const RelaxSoundsRoute(),
          title: tr('general.sounds'),
          subtitle: null,
          icon: const Icon(SpIcons.musicNote),
        ),
      if (fromSideBar) ...[
        SideItem.divider(),
        SideItem.custom(
          builder: (context, {bool fromSideBar = false, bool fromEndDrawer = false}) {
            return Consumer<TagsProvider>(
              builder: (context, tagProvider, child) {
                final tags = tagProvider.tags?.items ?? <TagDbModel>[];
                return Column(
                  children: [
                    const TagHeader(),
                    ...tags.map((tag) {
                      final route = ShowTagRoute(tag: tag, storyViewOnly: false);

                      return SideItem.buildSideBarItem(
                        context: context,
                        icon: const Icon(SpIcons.tag),
                        title: tag.title,
                        subtitle: null,
                        routeName: route.routeName,
                        onTap: () => navigate(
                          context: context,
                          fromSideBar: true,
                          route: route,
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ],
    ];
  }

  static List<BaseSideItem> getMoreOptions({
    bool fromSideBar = false,
    bool fromEndDrawer = false,
  }) {
    return [
      SideItem(
        route: ArchivesRoute(pathType: .archives),
        title: tr('general.path_type.archives'),
        subtitle: null,
        icon: const Icon(SpIcons.archive),
      ),
      SideItem(
        route: ArchivesRoute(pathType: .bins),
        title: tr('general.path_type.bins'),
        subtitle: null,
        icon: const Icon(SpIcons.delete),
      ),
      SideItem.divider(),
      SideItem.custom(
        builder: (context) {
          return BackupTile(
            onNavigate: (BaseRoute route) => navigate(
              context: context,
              fromSideBar: fromSideBar,
              route: route,
            ),
          );
        },
      ),
      SideItem.divider(),
      if (kIAPEnabled)
        SideItem(
          route: const AddOnsRoute(),
          title: tr('page.add_ons.title'),
          subtitle: null,
          icon: const Icon(SpIcons.addOns),
        ),
      if (kIAPEnabled)
        SideItem(
          route: const RewardsRoute(),
          title: tr('page.rewards.title'),
          subtitle: null,
          icon: const SpGiftAnimatedIcon(),
        ),
      SideItem(
        route: SettingsRoute(),
        title: tr('page.settings.title'),
        subtitle: null,
        icon: const Icon(SpIcons.setting),
      ),
      if (kIAPEnabled) SideItem.divider(),
      SideItem(
        route: CommunityRoute(),
        title: tr('page.community.title'),
        subtitle: null,
        icon: const Icon(SpIcons.forum),
      ),
      SideItem(
        route: null,
        title: tr('list_tile.rate.title'),
        subtitle: null,
        icon: const Icon(SpIcons.star),
        onTap: (context) => AppStoreOpenerService.call(),
      ),
      SideItem(
        route: null,
        title: tr('list_tile.share_app.title'),
        subtitle: tr('list_tile.share_app.subtitle'),
        icon: const Icon(SpIcons.share),
        onTap: (context) => SpShareAppBottomSheet().show(context: context),
      ),
    ];
  }
}
