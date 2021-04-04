import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:launch_review/launch_review.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:write_story/app_helper/app_helper.dart';
import 'package:write_story/constants/config_constant.dart';
import 'package:write_story/database/w_database.dart';
import 'package:write_story/mixins/dialog_mixin.dart';
import 'package:write_story/mixins/snakbar_mixin.dart';
import 'package:write_story/models/db_backup_model.dart';
import 'package:write_story/notifier/auth_notifier.dart';
import 'package:write_story/notifier/home_screen_notifier.dart';
import 'package:write_story/notifier/remote_database_notifier.dart';
import 'package:write_story/notifier/theme_notifier.dart';
import 'package:write_story/services/google_drive_api_service.dart';
import 'package:write_story/widgets/vt_ontap_effect.dart';
import 'package:write_story/widgets/w_icon_button.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingScreen extends HookWidget with DialogMixin, WSnackBar {
  final double avatarSize = 72;
  final ValueNotifier<double> scrollOffsetNotifier = ValueNotifier<double>(0);
  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    scrollController.addListener(() {
      scrollOffsetNotifier.value = scrollController.offset;
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.surface,
        textTheme: Theme.of(context).textTheme,
        title: Text(
          "Setting",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: WIconButton(
          iconData: Icons.arrow_back,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        controller: scrollController,
        children: [
          buildRelateToAccount(),
          buildRelateToTheme(),
          buildRelateToLanguage(),
          // buildFontStyle(),
          buildRate(),
          buildAboutUs(context),
          buildShareApp(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget buildFontStyle() {
    return WListTile(
      iconData: Icons.font_download_sharp,
      titleText: "Font Style",
      subtitleText: "Quicksand",
      onTap: () {},
    );
  }

  Widget buildAboutUs(BuildContext context) {
    return WListTile(
      iconData: Icons.info,
      titleText: "About us",
      onTap: () {
        final _theme = Theme.of(context);
        final _textTheme = Theme.of(context).textTheme;
        showAboutDialog(
          context: context,
          applicationName: "Story",
          applicationVersion: "v1.0.0+7",
          applicationLegalese: tr("info.app_detail"),
          children: [
            const SizedBox(height: 24.0),
            Text(
              tr("position.thea"),
              style: _textTheme.caption?.copyWith(
                color: _theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            Text(
              tr("name.thea"),
              style: _textTheme.caption!.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(),
            Text(
              tr("position.menglong"),
              style: _textTheme.caption?.copyWith(
                color: _theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            Text(
              tr("name.menglong"),
              style: _textTheme.caption!.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          applicationIcon: ClipRRect(
            borderRadius: ConfigConstant.circlarRadius1,
            child: Image.asset(
              "assets/icons/app_icon.png",
              height: ConfigConstant.iconSize3,
            ),
          ),
        );
      },
    );
  }

  Widget buildRate() {
    return WListTile(
      iconData: Icons.rate_review,
      titleText: "Rate us",
      onTap: () async {
        onTapVibrate();
        await LaunchReview.launch();
      },
    );
  }

  Widget buildShareApp() {
    return WListTile(
      iconData: Icons.share,
      titleText: "Share",
      onTap: () async {
        onTapVibrate();
        await Share.share(
          "StoryPad - Write Your Story, Note, Diary. Download now on Play Store: https://play.google.com/store/apps/details?id=com.tc.writestory",
        );
      },
    );
  }

  Consumer buildRelateToLanguage() {
    return Consumer(
      builder: (context, reader, child) {
        return WListTile(
          iconData: Icons.language,
          titleText: "Language",
          subtitleText:
              context.locale.languageCode == "km" ? "ខ្មែរ" : "English",
          onTap: () {
            final dialog = Dialog(
              child: Wrap(
                children: [
                  ListTile(
                    title: Text("ខ្មែរ", textAlign: TextAlign.center),
                    onTap: () {
                      onTapVibrate();
                      Navigator.of(context).pop();
                      context.setLocale(Locale("km"));
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    title: Text("English", textAlign: TextAlign.center),
                    onTap: () {
                      onTapVibrate();
                      Navigator.of(context).pop();
                      context.setLocale(Locale("en"));
                    },
                  ),
                ],
              ),
            );
            showWDialog(context: context, child: dialog);
          },
        );
      },
    );
  }

  Consumer buildRelateToTheme() {
    return Consumer(
      builder: (context, reader, child) {
        final notifier = reader(themeProvider);
        return Column(
          children: [
            WListTile(
              iconData: Icons.nightlight_round,
              titleText: "Theme",
              subtitleText: notifier.isDarkMode == null
                  ? "System"
                  : notifier.isDarkMode == true
                      ? "Dark"
                      : "Light",
              onTap: () {
                final dialog = Dialog(
                  child: Wrap(
                    children: [
                      ListTile(
                        title: Text(
                          "Dark",
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          onTapVibrate();
                          Navigator.of(context).pop();
                          notifier.setDarkMode(true);
                        },
                      ),
                      const Divider(height: 0),
                      ListTile(
                        title: Text(
                          "Light",
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          onTapVibrate();
                          Navigator.of(context).pop();
                          notifier.setDarkMode(false);
                        },
                      ),
                      const Divider(height: 0),
                      ListTile(
                        title: Text(
                          "System",
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          onTapVibrate();
                          Navigator.of(context).pop();
                          notifier.setDarkMode(null);
                        },
                      ),
                    ],
                  ),
                );
                showWDialog(context: context, child: dialog);
              },
            ),
            WListTile(
              iconData: Icons.list_alt,
              titleText: "Layout",
              subtitleText: notifier.isNormalList ? "Normal" : "Tab",
              onTap: () {
                final dialog = Dialog(
                  child: Wrap(
                    children: [
                      ListTile(
                        title: Text("Normal"),
                        subtitle: Text(
                          "Display all stories as a list view",
                        ),
                        onTap: () {
                          onTapVibrate();
                          Navigator.of(context).pop();
                          notifier.setListLayout(true);
                        },
                      ),
                      const Divider(height: 0),
                      ListTile(
                        title: Text("Tab"),
                        subtitle: Text(
                          "Display all stories by divide them by month",
                        ),
                        onTap: () {
                          onTapVibrate();
                          Navigator.of(context).pop();
                          notifier.setListLayout(false);
                        },
                      ),
                    ],
                  ),
                );
                showWDialog(context: context, child: dialog);
              },
            ),
          ],
        );
      },
    );
  }

  Consumer buildRelateToAccount() {
    return Consumer(
      builder: (context, reader, child) {
        final userNotifier = reader(authenticationProvider);
        final dbNotifier = reader(remoteDatabaseProvider)..load();
        final WDatabase database = WDatabase.instance;

        final bool imageNotNull = userNotifier.isAccountSignedIn &&
            userNotifier.user!.photoURL != null;
        // Variable holding the original String portion of the url that will be replaced
        String originalPieceOfUrl = "s96-c";

        // Variable holding the new String portion of the url that does the replacing, to improve image quality
        String newPieceOfUrlToAdd = "s0";

        String? imageUrl;
        if (imageNotNull) {
          imageUrl = "${userNotifier.user!.photoURL}".replaceAll(
            "$originalPieceOfUrl",
            "$newPieceOfUrlToAdd",
          );
        }

        return Column(
          children: [
            if (imageNotNull) buildProfile(context, imageUrl!),
            ExpansionTile(
              backgroundColor: Theme.of(context).colorScheme.surface,
              collapsedBackgroundColor: Theme.of(context).colorScheme.surface,
              initiallyExpanded: true,
              leading: AspectRatio(
                aspectRatio: 1.5 / 2,
                child: Container(
                  height: double.infinity,
                  child: Icon(Icons.person),
                ),
              ),
              title: Text("Google Account"),
              subtitle: Text(
                userNotifier.isAccountSignedIn
                    ? "${userNotifier.user?.email}"
                    : tr("msg.login.info"),
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5)),
              ),
              children: [
                if (userNotifier.isAccountSignedIn)
                  VTOnTapEffect(
                    onTap: () {},
                    child: WListTile(
                      iconData: Icons.backup,
                      titleText: "Sync data",
                      subtitleText: tr("msg.backup.export"),
                      onTap: () {
                        onTapVibrate();
                        showSnackBar(
                          context: context,
                          title: tr("msg.backup.export.warning"),
                          onActionPressed: () async {
                            String backup = await database.generateBackup();
                            final backupModel = DbBackupModel(
                              createOn: Timestamp.now(),
                              db: backup,
                            );
                            final bool success =
                                await dbNotifier.replace(backupModel);
                            if (success) {
                              showSnackBar(
                                context: context,
                                title: tr("msg.backup.export.success"),
                              );
                            } else {
                              showSnackBar(
                                context: context,
                                title: tr("msg.backup.export.fail"),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                if (userNotifier.isAccountSignedIn && dbNotifier.backup != null)
                  VTOnTapEffect(
                    onTap: () {},
                    child: WListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      iconData: Icons.restore,
                      titleText: "Restore",
                      subtitleText: tr(
                        "msg.backup.import",
                        namedArgs: {
                          "DATE": AppHelper.dateFormat(context).format(
                                  dbNotifier.backup!.createOn.toDate()) +
                              ", " +
                              AppHelper.timeFormat(context)
                                  .format(dbNotifier.backup!.createOn.toDate())
                        },
                      ),
                      onTap: () async {
                        onTapVibrate();
                        final bool success =
                            await database.restoreBackup(dbNotifier.backup!.db);
                        if (success) {
                          await context.read(homeScreenProvider).load();
                          onTapVibrate();
                          showSnackBar(
                            context: context,
                            title: tr("msg.backup.import.success"),
                          );
                        } else {
                          onTapVibrate();
                          showSnackBar(
                            context: context,
                            title: tr("msg.backup.import.fail"),
                          );
                        }
                      },
                    ),
                  ),
                VTOnTapEffect(
                  onTap: () {},
                  child: WListTile(
                    tileColor: Theme.of(context).colorScheme.surface,
                    iconData: userNotifier.isAccountSignedIn
                        ? Icons.logout
                        : Icons.login,
                    titleText:
                        userNotifier.isAccountSignedIn ? "Sign out" : "Connect",
                    onTap: () async {
                      onTapVibrate();
                      if (userNotifier.isAccountSignedIn) {
                        await userNotifier.signOut();
                        context.read(remoteDatabaseProvider).reset();
                      } else {
                        bool success = await userNotifier.logAccount();
                        if (success == true) {
                          onTapVibrate();
                          showSnackBar(
                            context: context,
                            title: tr("msg.login.success"),
                          );
                        } else {
                          onTapVibrate();
                          showSnackBar(
                            context: context,
                            title: userNotifier.service?.errorMessage != null
                                ? userNotifier.service?.errorMessage as String
                                : tr("msg.login.fail"),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget buildProfile(BuildContext context, String imageUrl) {
    final width = MediaQuery.of(context).size.width;

    return ValueListenableBuilder(
      valueListenable: scrollOffsetNotifier,
      builder: (context, value, child) {
        final bool isCollapse = scrollOffsetNotifier.value < 200;
        final _avatarSize = isCollapse ? width : this.avatarSize;
        final _padding = isCollapse ? EdgeInsets.zero : EdgeInsets.all(16);

        return AnimatedContainer(
          duration: ConfigConstant.fadeDuration,
          width: width,
          height: width,
          padding: _padding,
          alignment: Alignment.bottomCenter,
          color: Theme.of(context).colorScheme.background,
          child: AnimatedOpacity(
            duration: ConfigConstant.fadeDuration,
            opacity: scrollOffsetNotifier.value < 350 ? 1 : 0,
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                AnimatedContainer(
                  duration: ConfigConstant.fadeDuration,
                  curve: Curves.linear,
                  width: _avatarSize,
                  height: _avatarSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      isCollapse ? 0 : _avatarSize,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: ConfigConstant.fadeDuration,
                  width: double.infinity,
                  height: 72,
                  margin: EdgeInsets.only(
                      left: isCollapse ? 0 : this.avatarSize + 16),
                  decoration: BoxDecoration(
                    borderRadius: isCollapse
                        ? BorderRadius.zero
                        : ConfigConstant.circlarRadius2,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(isCollapse ? 1 : 1),
                  ),
                  child: ListTile(
                    title: Text(
                      "Google Drive",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    subtitle: Text(
                      isCollapse
                          ? "Check all images that you've uploaded"
                          : "Check all images",
                      maxLines: 1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    trailing: Container(
                      width: 24,
                      child: WIconButton(
                        iconData: Icons.arrow_right,
                        onPressed: () {},
                        iconColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    onTap: () async {
                      onTapVibrate();
                      final String? id =
                          await GoogleDriveApiService.getStoryFolderId();
                      if (id != null) {
                        launch(
                          "https://drive.google.com/drive/folders/$id?usp=sharing",
                        );
                      } else {
                        showSnackBar(
                          context: context,
                          title: "No folder id found",
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WListTile extends StatelessWidget {
  const WListTile({
    Key? key,
    required this.iconData,
    required this.titleText,
    required this.onTap,
    this.subtitleText,
    this.tileColor,
  }) : super(key: key);

  final Color? tileColor;
  final IconData iconData;
  final String titleText;
  final String? subtitleText;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: tileColor,
      leading: AspectRatio(
        aspectRatio: 1.5 / 2,
        child: Container(
          height: double.infinity,
          child: Icon(iconData),
        ),
      ),
      title: Text(titleText),
      subtitle: subtitleText != null
          ? Text(
              subtitleText!,
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}