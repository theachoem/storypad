import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' show tr, BuildContextEasyLocalizationExtension;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "package:storypad/core/constants/app_constants.dart";
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/services/app_store_opener_service.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/types/backup_connection_status.dart';
import 'package:storypad/core/types/new_badge.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/archives/archives_view.dart' show ArchivesRoute;
import 'package:storypad/views/backup_services/backup_services_view.dart';
import 'package:storypad/views/home/home_view_model.dart' show HomeViewModel;
import 'package:storypad/views/home/local_widgets/end_drawer/home_end_drawer_state.dart';
import 'package:storypad/views/home/local_widgets/end_drawer/survey_banner.dart';
import 'package:storypad/views/home/years_view/home_years_view.dart' show HomeYearsRoute, HomeYearsView;
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/rewards/rewards_view.dart';
import 'package:storypad/views/root/root_view_model.dart';
import 'package:storypad/views/tags/tags_view.dart' show TagsRoute;
import 'package:storypad/views/settings/settings_view.dart' show SettingsRoute;
import 'package:storypad/core/extensions/color_scheme_extension.dart' show ColorSchemeExtension;
import 'package:storypad/views/community/community_view.dart' show CommunityRoute;
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/bottom_sheets/sp_share_app_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_gift_animated_icon.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_new_badge_builder.dart';
import 'package:storypad/widgets/sp_theme_mode_icon.dart';

part 'home_end_drawer_header.dart';
part 'community_tile.dart';
part 'backup_tile.dart';
part 'add_ons_tile.dart';

class HomeEndDrawer extends StatelessWidget {
  const HomeEndDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    if (viewModel.endDrawerState == HomeEndDrawerState.showYearsView) {
      if (viewModel.showFadeInYearEndDrawer) {
        return Material(
          color: ColorScheme.of(context).surface,
          child: SpFadeIn(
            builder: (context, animation, child) {
              return SpFadeIn(
                child: AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()..spTranslate(lerpDouble(24.0, 0, animation.value)!, 0.0),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: HomeYearsView(
              params: HomeYearsRoute(viewModel: viewModel),
            ),
          ),
        );
      } else {
        return HomeYearsView(
          params: HomeYearsRoute(viewModel: viewModel),
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: SpThemeModeIcon(
              parentContext: context,
            ),
            onPressed: () {
              context.read<DevicePreferencesProvider>().toggleThemeMode(context);
            },
          ),
        ],
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom + 16.0,
        ),
        children: [
          SurveyBanner(context: context, viewModel: viewModel),
          _HomeEndDrawerHeader(viewModel),
          const Divider(height: 1),
          const SizedBox(height: 8.0),
          ValueListenableBuilder(
            valueListenable: context.read<RootViewModel>().sideBarInfoNotifier,
            builder: (context, sideBarInfo, child) {
              bool bigScreen = sideBarInfo?.bigScreen ?? false;
              return Visibility(
                visible: !bigScreen,
                child: buildTagsTile(context),
              );
            },
          ),
          if (kStoryPad)
            ValueListenableBuilder(
              valueListenable: context.read<RootViewModel>().sideBarInfoNotifier,
              builder: (context, sideBarInfo, child) {
                bool bigScreen = sideBarInfo?.bigScreen ?? false;
                return Visibility(
                  visible: !bigScreen,
                  child: ListTile(
                    leading: const Icon(SpIcons.photo),
                    title: Text(tr("page.library.title")),
                    onTap: () => LibraryRoute().push(context),
                  ),
                );
              },
            ),
          buildArchiveTile(context),
          buildBinsTile(context),
          const Divider(),
          _BackupTile(),
          const Divider(),
          if (kIAPEnabled) const _AddOnsTile(),
          if (kIAPEnabled)
            ListTile(
              leading: const SpGiftAnimatedIcon(),
              title: Text(tr('page.rewards.title')),
              onTap: () => const RewardsRoute().push(context),
            ),
          buildSettingTile(context),
          const Divider(),
          const _CommunityTile(),
          ListTile(
            leading: const Icon(SpIcons.star),
            title: Text(tr("list_tile.rate.title")),
            onTap: () => AppStoreOpenerService.call(),
          ),
          ListTile(
            leading: const Icon(SpIcons.share),
            title: Text(tr("list_tile.share_app.title")),
            subtitle: Text(tr("list_tile.share_app.subtitle")),
            onTap: () => SpShareAppBottomSheet().show(context: context),
          ),
        ],
      ),
    );
  }

  Widget buildTagsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.tag),
      title: Text(tr("page.tags.title")),
      onTap: () => TagsRoute().push(context),
    );
  }

  Widget buildArchiveTile(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.archive),
      title: Text(tr('general.path_type.archives')),
      onTap: () => ArchivesRoute(pathType: .archives).push(context),
    );
  }

  Widget buildBinsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.delete),
      title: Text(tr('general.path_type.bins')),
      onTap: () => ArchivesRoute(pathType: .bins).push(context),
    );
  }

  Widget buildSettingTile(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.setting),
      title: Text(tr("page.settings.title")),
      onTap: () => SettingsRoute().push(context),
    );
  }
}
