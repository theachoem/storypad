import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';
import 'package:storypad/views/backups/backups_view_model.dart';
import 'package:storypad/widgets/sp_default_scroll_controller.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

class UserProfileCollapsibleTile extends StatelessWidget {
  final BackupsViewModel viewModel;
  final BaseBackupSource source;
  final double avatarSize;

  const UserProfileCollapsibleTile({
    super.key,
    required this.viewModel,
    required this.source,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      bool tablet = constraint.maxWidth > constraint.maxHeight;
      final width = constraint.maxWidth;

      return SpDefaultScrollController.listenToOffet(
        builder: (context, double offset, child) {
          final bool isCollapsed = tablet || offset > 200;
          final avatarSize = !isCollapsed ? width : this.avatarSize;
          final padding = !isCollapsed ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0);

          return AnimatedContainer(
            duration: Durations.long1,
            curve: Curves.easeOutQuart,
            width: width,
            height: tablet ? kToolbarHeight + 24 * 2 : width,
            padding: padding,
            alignment: Alignment.bottomLeft,
            child: AnimatedOpacity(
              duration: Durations.long1,
              curve: Curves.decelerate,
              opacity: offset < 350 ? 1 : 0,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  buildPhoto(avatarSize, isCollapsed, context),
                  buildProfileInfoTile(isCollapsed, context),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget buildProfileInfoTile(bool isCollapsed, BuildContext context) {
    return AnimatedContainer(
      duration: Durations.long1,
      width: double.infinity,
      curve: Curves.easeOutQuart,
      margin: EdgeInsets.only(left: !isCollapsed ? 0 : avatarSize + 8),
      decoration: BoxDecoration(
        borderRadius: !isCollapsed ? BorderRadius.zero : BorderRadius.circular(8.0),
        color: ColorScheme.of(context).primary,
      ),
      child: SpPopupMenuButton(
        smartDx: true,
        dyGetter: (dy) => dy + 36,
        items: (BuildContext context) {
          return [
            SpPopMenuItem(
              title: tr('button.sign_out'),
              titleStyle: TextStyle(color: ColorScheme.of(context).error),
              onPressed: () => viewModel.signOut(context),
            )
          ];
        },
        builder: (callback) {
          if (source.isSignedIn == true) {
            return ListTile(
              onTap: callback,
              title: Text(
                source.displayName ?? "",
                style: TextStyle(color: ColorScheme.of(context).onPrimary),
              ),
              subtitle: source.email != null
                  ? Text(
                      source.email!,
                      style: TextStyle(color: ColorScheme.of(context).onPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
              trailing: Icon(
                SpIcons.moreVert,
                color: ColorScheme.of(context).onPrimary,
              ),
            );
          } else {
            return ListTile(
              onTap: () => viewModel.signIn(context),
              title: Text(
                tr('list_tile.backup.title'),
                style: TextStyle(color: ColorScheme.of(context).onPrimary),
              ),
              subtitle: Text(
                tr("list_tile.backup.unsignin_subtitle"),
                style: TextStyle(color: ColorScheme.of(context).onPrimary),
              ),
              trailing: Icon(
                SpIcons.googleDrive,
                color: ColorScheme.of(context).onPrimary,
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildPhoto(double avatarSize, bool isCollapsed, BuildContext context) {
    bool hasPhoto = source.smallImageUrl != null && source.bigImageUrl != null;

    return AnimatedContainer(
      duration: Durations.medium1,
      curve: Curves.easeOutQuart,
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          !isCollapsed ? 0 : avatarSize,
        ),
        image: hasPhoto
            ? DecorationImage(
                image: CachedNetworkImageProvider(isCollapsed ? source.smallImageUrl! : source.bigImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasPhoto
          ? const Icon(
              SpIcons.profile,
              size: 36,
            )
          : null,
    );
  }
}
