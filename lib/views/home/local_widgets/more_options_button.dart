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
            title: tr("list_tile.licenses.title"),
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
              title: tr("list_tile.google_drive_api.title"),
              subtitle: tr("list_tile.google_drive_api.subtitle_args", namedArgs: {
                'REQUESTS_COUNT': GoogleDriveService.instance.requestCount.toString(),
              }),
            )
        ];
      },
      builder: (open) {
        return IconButton(
          tooltip: tr('button.more_options'),
          onPressed: open,
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }

  SpPopMenuItem buildOpenSourceRepo(BuildContext context) {
    return SpPopMenuItem(
      leadingIconData: Icons.code,
      title: tr("list_tile.source_code.title"),
      onPressed: () {
        UrlOpenerService.openInCustomTab(context, RemoteConfigService.sourceCodeUrl.get());
      },
    );
  }

  SpPopMenuItem buildPolicyPrivacyItem(BuildContext context) {
    return SpPopMenuItem(
      leadingIconData: Icons.policy,
      title: tr("list_tile.privacy_policy.title"),
      onPressed: () {
        UrlOpenerService.openInCustomTab(context, RemoteConfigService.policyPrivacyUrl.get());
      },
    );
  }

  SpPopMenuItem buildRateItem(BuildContext context) {
    return SpPopMenuItem(
      leadingIconData: Icons.star,
      title: tr("list_tile.rate.title"),
      titleStyle: TextStyle(color: ColorScheme.of(context).bootstrap.warning.color),
      onPressed: () async {
        await AppStoreOpenerService.call();
      },
    );
  }
}
