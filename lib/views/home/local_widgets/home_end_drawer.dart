import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/services/remote_config/remote_config_service.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/app_locks/app_locks_view.dart';
import 'package:storypad/views/archives/archives_view.dart';
import 'package:storypad/views/home/home_view_model.dart';
import 'package:storypad/views/home/local_widgets/backup_tile.dart';
import 'package:storypad/views/home/local_widgets/community_tile.dart';
import 'package:storypad/views/home/local_widgets/language_tile.dart';
import 'package:storypad/views/home/years_view/home_years_view.dart';
import 'package:storypad/views/library/library_view.dart';
import 'package:storypad/views/search/search_view.dart';
import 'package:storypad/views/tags/tags_view.dart';
import 'package:storypad/views/theme/theme_view.dart';

part 'home_end_drawer_header.dart';

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
          const BackupTile(),
          const Divider(),
          buildThemeTile(context),
          LanguageTile(),
          buildAppLockTile(context),
          if (RemoteConfigService.communityUrl.get().trim().isNotEmpty == true) ...[
            const Divider(),
            CommunityTile(),
          ],
        ],
      ),
    );
  }

  Widget buildSearchTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(tr("page.search.title")),
      onTap: () => SearchRoute(
        initialFilter: SearchFilterObject(
          years: {viewModel.year},
          types: {PathType.docs},
          tagId: null,
          assetId: null,
        ),
      ).push(context),
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
