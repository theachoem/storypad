part of '../home_view.dart';

class _MoreOptionsButton extends StatelessWidget {
  const _MoreOptionsButton();

  @override
  Widget build(BuildContext context) {
    return SpPopupMenuButton(
      fromAppBar: true,
      items: (context) {
        return [
          buildRateItem(context),
          buildPolicyPrivacyItem(context),
          buildOpenSourceRepo(context),
          SpPopMenuItem(
            leadingIconData: MdiIcons.license,
            title: 'Licenses',
            onPressed: () {
              AnalyticsService.instance.logLicenseView();
              showLicensePage(
                context: context,
                applicationName: kPackageInfo.appName,
                applicationLegalese: '©${DateTime.now().year}',
                applicationVersion: "${kPackageInfo.version}+${kPackageInfo.buildNumber}",
              );
            },
          ),
          if (kDebugMode)
            SpPopMenuItem(
              leadingIconData: MdiIcons.googleDrive,
              title: "Google Drive API",
              subtitle: "${GoogleDriveService.instance.requestCount} requests",
            )
        ];
      },
      builder: (open) {
        return IconButton(
          onPressed: open,
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }

  SpPopMenuItem buildOpenSourceRepo(BuildContext context) {
    return SpPopMenuItem(
      leadingIconData: Icons.code,
      title: 'Source Code',
      onPressed: () {
        UrlOpenerService.openInCustomTab(context, 'https://github.com/theachoem/storypad');
      },
    );
  }

  SpPopMenuItem buildPolicyPrivacyItem(BuildContext context) {
    return SpPopMenuItem(
      leadingIconData: Icons.policy,
      title: 'Privacy & Policy',
      onPressed: () {
        UrlOpenerService.openInCustomTab(context, 'https://github.com/theachoem/storypad/wiki/Privacy-Policy');
      },
    );
  }

  SpPopMenuItem buildRateItem(BuildContext context) {
    return SpPopMenuItem(
      leadingIconData: Icons.star,
      title: 'Rate the App',
      titleStyle: TextStyle(color: ColorScheme.of(context).bootstrap.warning.color),
      onPressed: () async {
        final InAppReview inAppReview = InAppReview.instance;

        Future<void> openStore() async {
          String deeplink = 'market://details?id=PACKAGE_NAME';
          bool launched = await NewVersionPlus().launchApplicationStore(deeplink);
          if (launched) return;
          await inAppReview.openStoreListing();
        }

        if (await inAppReview.isAvailable()) {
          try {
            await inAppReview.requestReview();
          } catch (e) {
            debugPrint(e.toString());
            await openStore();
          }
        } else {
          await openStore();
        }
      },
    );
  }
}
