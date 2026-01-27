import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/app_store_opener_service.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/archives/archives_view.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/community/community_view.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/survey_banner.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/search/search_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_app_bottom_sheet.dart';
import 'package:storypad/widgets/side_items/local_widgets/backup_tile.dart';
import 'package:storypad/widgets/side_items/local_widgets/home_year_switcher_header.dart';
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/rewards/rewards_view.dart';
import 'package:storypad/views/settings/settings_view.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_gift_animated_icon.dart';
import 'package:storypad/widgets/sp_icons.dart';

part 'local_widgets/tag_header.dart';
part 'side_item.dart';

const double _leadingPaddedSize = 12.0;

class SideItems {
  static List<IconButtonSideItem> getSideMenuItems() {
    return [
      IconButtonSideItem(
        route: const HomeRoute(),
        title: tr('page.home.title'),
        iconData: SpIcons.home,
        selectedIconData: SpIcons.home,
        onTap: (context, route) => context.read<RootProvider>().navigate(route),
      ),
      IconButtonSideItem(
        route: SearchRoute(),
        title: tr('page.search.title'),
        iconData: SpIcons.search,
        selectedIconData: SpIcons.search,
        onTap: (context, route) => context.read<RootProvider>().navigate(route),
      ),
      IconButtonSideItem(
        route: CalendarRoute(
          initialMonth: DateTime.now().month,
          initialYear: DateTime.now().year,
          initialSegment: .mood,
        ),
        title: tr('page.calendar.title'),
        iconData: SpIcons.calendar,
        selectedIconData: SpIcons.calendar,
        onTap: (context, route) => context.read<RootProvider>().navigate(route),
      ),
      IconButtonSideItem(
        route: TagsRoute(),
        title: tr('page.tags.title'),
        iconData: SpIcons.tag,
        selectedIconData: SpIcons.tag,
        onTap: (context, route) => context.read<RootProvider>().navigate(route),
      ),
      if (kIAPEnabled)
        IconButtonSideItem(
          route: const RelaxSoundsRoute(),
          title: tr('general.sounds'),
          iconData: SpIcons.musicNote,
          selectedIconData: SpIcons.musicNote,
          onTap: (context, route) => context.read<RootProvider>().navigate(route),
        ),
    ];
  }

  static List<BaseSideItem> getEndDrawerItems(HomeViewModel homeViewModel) {
    return [
      CustomSideItem.custom(builder: (context) => SurveyBanner(homeViewModel: homeViewModel)),
      CustomSideItem.custom(builder: (context) => HomeYearSwitcherHeader(homeViewModel: homeViewModel)),
      CustomSideItem.divider(),
      ListTileSideItem(
        title: tr('page.tags.title'),
        subtitle: null,
        icon: const Icon(SpIcons.tag),
        onTap: (context) => TagsRoute().push(context),
      ),
      ListTileSideItem(
        title: tr('page.library.title'),
        subtitle: null,
        icon: const Icon(SpIcons.photo),
        onTap: (context) => LibraryRoute().push(context),
      ),
      ListTileSideItem(
        title: tr('general.path_type.archives'),
        subtitle: null,
        icon: const Icon(SpIcons.archive),
        onTap: (context) => ArchivesRoute(pathType: .archives).push(context),
      ),
      ListTileSideItem(
        title: tr('general.path_type.bins'),
        subtitle: null,
        icon: const Icon(SpIcons.delete),
        onTap: (context) => ArchivesRoute(pathType: .bins).push(context),
      ),
      CustomSideItem.divider(),
      CustomSideItem.custom(
        builder: (context) {
          return BackupTile(onNavigate: (BaseRoute route) => route.push(context));
        },
      ),
      CustomSideItem.divider(),
      if (kIAPEnabled)
        ListTileSideItem(
          title: tr('page.add_ons.title'),
          subtitle: null,
          icon: const Icon(SpIcons.addOns),
          onTap: (context) => const AddOnsRoute().push(context),
        ),
      if (kIAPEnabled)
        ListTileSideItem(
          title: tr('page.rewards.title'),
          subtitle: null,
          icon: const SpGiftAnimatedIcon(),
          onTap: (context) => const RewardsRoute().push(context),
        ),
      ListTileSideItem(
        title: tr('page.settings.title'),
        subtitle: null,
        icon: const Icon(SpIcons.setting),
        onTap: (context) => SettingsRoute().push(context),
      ),
      if (kIAPEnabled) CustomSideItem.divider(),
      ListTileSideItem(
        title: tr('page.community.title'),
        subtitle: null,
        icon: const Icon(SpIcons.forum),
        onTap: (context) => CommunityRoute().push(context),
      ),
      ListTileSideItem(
        title: tr('list_tile.rate.title'),
        subtitle: null,
        icon: const Icon(SpIcons.star),
        onTap: (context) => AppStoreOpenerService.call(),
      ),
      ListTileSideItem(
        title: tr('list_tile.share_app.title'),
        subtitle: tr('list_tile.share_app.subtitle'),
        icon: const Icon(SpIcons.share),
        onTap: (context) => SpShareAppBottomSheet().show(context: context),
      ),
    ];
  }
}
