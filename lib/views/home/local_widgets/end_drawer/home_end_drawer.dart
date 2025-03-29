import 'package:easy_localization/easy_localization.dart' show tr, BuildContextEasyLocalizationExtension;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:storypad/core/constants/app_constants.dart" show kStoryPad;
import 'package:storypad/core/constants/locale_constants.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart' show RemoteConfigService;
import 'package:storypad/views/app_locks/app_locks_view.dart' show AppLocksRoute;
import 'package:storypad/views/archives/archives_view.dart' show ArchivesRoute;
import 'package:storypad/views/home/home_view_model.dart' show HomeViewModel;
import 'package:storypad/views/home/years_view/home_years_view.dart' show HomeYearsRoute;
import 'package:storypad/views/languages/languages_view.dart' show LanguagesRoute;
import 'package:storypad/views/library/library_view.dart' show LibraryRoute;
import 'package:storypad/views/search/search_view.dart' show SearchRoute;
import 'package:storypad/views/tags/tags_view.dart' show TagsRoute;
import 'package:storypad/views/theme/theme_view.dart' show ThemeRoute;
import 'package:storypad/core/extensions/color_scheme_extension.dart' show ColorSchemeExtension;
import 'package:storypad/views/community/community_view.dart' show CommunityRoute;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/views/backups/backups_view.dart';

part 'home_end_drawer_header.dart';
part 'community_tile.dart';
part 'language_tile.dart';
part 'backup_tile.dart';

class HomeEndDrawer extends StatelessWidget {
  const HomeEndDrawer(this.viewModel, {super.key});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop())
        ],
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom + 16.0,
        ),
        children: [
          _HomeEndDrawerHeader(viewModel),
          const Divider(height: 1),
          const SizedBox(height: 8.0),
          buildSearchTile(context),
          buildTagsTile(context),
          buildArchiveBinTile(context),
          if (kStoryPad)
            ListTile(
              leading: const Icon(Icons.photo_album_outlined),
              title: Text(tr("page.library.title")),
              onTap: () => LibraryRoute().push(context),
            ),
          const Divider(),
          const _BackupTile(),
          const Divider(),
          buildThemeTile(context),
          _LanguageTile(),
          buildAppLockTile(context),
          if (RemoteConfigService.communityUrl.get().trim().isNotEmpty == true) ...[
            const Divider(),
            _CommunityTile(),
          ],
        ],
      ),
    );
  }

  Widget buildSearchTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(tr("page.search.title")),
      onTap: () => SearchRoute(initialYear: viewModel.currentYear).push(context),
    );
  }

  Widget buildTagsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sell_outlined),
      title: Text(tr("page.tags.title")),
      onTap: () => TagsRoute().push(context),
    );
  }

  Widget buildArchiveBinTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.archive_outlined),
      title: Text(tr("page.archive_or_bin.title")),
      onTap: () => ArchivesRoute().push(context),
    );
  }

  Widget buildThemeTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.color_lens_outlined),
      title: Text(tr("page.theme.title")),
      onTap: () => ThemeRoute().push(context),
    );
  }

  Widget buildAppLockTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: Text(tr("page.app_lock.title")),
      onTap: () => AppLocksRoute().push(context),
    );
  }
}
