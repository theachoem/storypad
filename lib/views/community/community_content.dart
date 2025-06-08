part of 'community_view.dart';

class _CommunityContent extends StatelessWidget {
  const _CommunityContent(this.viewModel);

  final CommunityViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(tr('page.community.title')),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right,
        ),
        children: [
          const _CommunityCard(),
          if (RemoteConfigService.faqUrl.get().trim().isNotEmpty == true)
            ListTile(
              leading: const Icon(SpIcons.question),
              title: Text(tr("list_tile.faq.title")),
              trailing: const Icon(SpIcons.keyboardRight),
              onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.faqUrl.get()),
            ),
          if (RemoteConfigService.policyPrivacyUrl.get().trim().isNotEmpty == true)
            ListTile(
              leading: const Icon(SpIcons.policy),
              title: Text(tr("list_tile.privacy_policy.title")),
              trailing: const Icon(SpIcons.keyboardRight),
              onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.policyPrivacyUrl.get()),
            ),
          if (RemoteConfigService.sourceCodeUrl.get().trim().isNotEmpty == true)
            ListTile(
              leading: const Icon(SpIcons.code),
              title: Text(tr("list_tile.source_code.title")),
              subtitle: Text(tr("list_tile.source_code.subtitle")),
              onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.sourceCodeUrl.get()),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(SpIcons.onboarding),
            title: Text(tr('general.onboard_page')),
            onTap: () => SpOnboardingWrapper.open(context),
          ),
          ListTile(
            leading: Icon(SpIcons.license),
            title: Text(tr("list_tile.licenses.title")),
            onTap: () {
              AnalyticsService.instance.logLicenseView();
              showLicensePage(
                context: context,
                applicationName: kPackageInfo.appName,
                applicationLegalese: '©${DateTime.now().year}',
                applicationVersion: "${kPackageInfo.version}+${kPackageInfo.buildNumber}",
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(SpIcons.star, color: ColorScheme.of(context).bootstrap.warning.color),
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
}
