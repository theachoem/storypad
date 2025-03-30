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
          SizedBox(height: 8.0),
          CommunityCard(),
          SizedBox(height: 12.0),
          ListTile(
            leading: Icon(Icons.question_mark_outlined),
            title: Text(tr("list_tile.faq.title")),
            onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.faqUrl.get()),
          ),
          ListTile(
            leading: Icon(Icons.policy_outlined),
            title: Text(tr("list_tile.privacy_policy.title")),
            onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.policyPrivacyUrl.get()),
          ),
          ListTile(
            leading: Icon(Icons.code),
            title: Text(tr("list_tile.source_code.title")),
            subtitle: Text(tr("list_tile.source_code.subtitle")),
            onTap: () => UrlOpenerService.openInCustomTab(context, RemoteConfigService.sourceCodeUrl.get()),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.waving_hand_outlined),
            title: Text(tr('general.onboard_page')),
            onTap: () => SpOnboardingWrappper.open(context),
          ),
          ListTile(
            leading: Icon(MdiIcons.license),
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
          Divider(),
          ListTile(
            leading: Icon(Icons.star_border),
            title: Text(tr("list_tile.rate.title")),
            onTap: () => AppStoreOpenerService.call(),
          ),
          ListTile(
            leading: Icon(Icons.ios_share_rounded),
            title: Text(tr("list_tile.share_app.title")),
            subtitle: Text(tr("list_tile.share_app.subtitle")),
            onTap: () => SpShareAppBottomSheet().show(context: context),
          ),
        ],
      ),
    );
  }
}
