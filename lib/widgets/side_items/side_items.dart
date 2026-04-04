import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/services/app_store_opener_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/archives/archives_view.dart';
import 'package:storypad/views/calendar/calendar_view.dart';
import 'package:storypad/views/community/community_view.dart';
import 'package:storypad/views/home/home_view.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/survey_banner.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/views/search/search_view.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_app_bottom_sheet.dart';
import 'package:storypad/widgets/side_items/local_widgets/backup_tile.dart';
import 'package:storypad/widgets/side_items/local_widgets/home_year_switcher_header.dart';
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/settings/settings_view.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_floating_music_note.dart';
import 'package:storypad/widgets/sp_icons.dart';

part 'local_widgets/tag_header.dart';
part 'side_item.dart';

const double _leadingPaddedSize = 12.0;

class SideItems {
  static List<IconButtonSideItem> getSideMenuItems({
    required bool enableRelaxSounds,
  }) {
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
      if (kIAPEnabled && enableRelaxSounds)
        IconButtonSideItem(
          route: const RelaxSoundsRoute(),
          title: tr('general.sounds'),
          iconData: SpIcons.musicNote,
          selectedIconData: SpIcons.musicNote,
          onTap: (context, route) => context.read<RootProvider>().navigate(route),
        ),
    ];
  }

  static List<BaseSideItem> getEndDrawerItems(BuildContext context, HomeViewModel homeViewModel) {
    bool showProBanner = kIAPEnabled && !context.read<InAppPurchaseProvider>().isProUser;

    return [
      CustomSideItem.custom(builder: (context) => SurveyBanner(homeViewModel: homeViewModel)),
      CustomSideItem.custom(builder: (context) => HomeYearSwitcherHeader(homeViewModel: homeViewModel)),
      if (showProBanner) ...[
        CustomSideItem.custom(
          builder: (context) {
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
              tileColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.onSecondary,
              iconColor: Theme.of(context).colorScheme.onSecondary,
              trailing: Icon(SpIcons.starCircle),
              title: Text(tr('list_tile.upgrade_to_pro.title')),
              subtitle: Text(tr('list_tile.upgrade_to_pro.subtitle')),
              onTap: () => const PaywallRoute().push(context),
            );
          },
        ),
      ] else ...[
        CustomSideItem.divider(),
      ],
      // CustomSideItem.divider(),
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
      ListTileSideItem(
        title: tr('page.add_ons.title'),
        subtitle: null,
        icon: const Icon(SpIcons.addOns),
        onTap: (context) => const AddOnsRoute().push(context),
      ),
      ListTileSideItem(
        title: tr('page.settings.title'),
        subtitle: null,
        icon: const Icon(SpIcons.setting),
        onTap: (context) => SettingsRoute().push(context),
      ),
      CustomSideItem.divider(),
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

  static List<TimelineSideBarItem> getTimelineSideBarItems({
    required HomeViewModel homeViewModel,
    required InAppPurchaseProvider iapProvider,
    required ValueNotifier<bool> showBadgeNotifer,
    required bool enableRelaxSounds,
  }) {
    return [
      if (kIAPEnabled && enableRelaxSounds)
        TimelineSideBarItem(
          icon: SpIcons.musicNote,
          tooltip: tr('paywall_features.relax_sounds.title'),
          wrap: (context, child) {
            return SpFadeIn.bound(
              child: SpFloatingMusicNote.wrapIfPlaying(child: child),
            );
          },
          onTap: (context) => const RelaxSoundsRoute().push(context),
        ),
      TimelineSideBarItem(
        icon: SpIcons.search,
        tooltip: tr('page.search.title'),
        wrap: (context, child) => SpFadeIn.bound(child: child),
        onTap: (context) => SearchRoute().push(context),
      ),
      TimelineSideBarItem(
        icon: SpIcons.calendar,
        tooltip: tr('page.calendar.title'),
        onTap: (context) {
          CalendarRoute(
            initialMonth: null,
            initialYear: homeViewModel.year,
            initialSegment: .mood,
          ).push(context);
        },
      ),
    ];
  }
}
