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
          ListTile(
            leading: Icon(
              SpIcons.favoriteFilled,
              color: AppTheme.isDarkMode(context) ? Colors.red[300] : Colors.red[700],
            ),
            title: Text(tr('page.support_us.title')),
            trailing: const Icon(SpIcons.keyboardRight),
            onTap: () async {
              await SupportUsRoute().push(context);
              if (context.mounted) {
                MessengerService.of(context).showSnackBar(tr('page.support_us.thank_you_message'));
              }
            },
          ),
          if (RemoteConfigService.policyPrivacyUrl.get().trim().isNotEmpty == true)
            ListTile(
              leading: const Icon(SpIcons.policy),
              title: Text(tr("general.privacy_policy")),
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
            onTap: () async {
              if (Scaffold.maybeOf(context)?.hasEndDrawer == true) {
                Scaffold.of(context).closeEndDrawer();
                SpOnboardingWrapper.open(context);
              } else {
                await Navigator.maybePop(context);
                SpOnboardingWrapper.open(HomeView.homeContext!);
              }
            },
          ),
          ListTile(
            leading: const Icon(SpIcons.license),
            title: Text(tr("list_tile.licenses.title")),
            onLongPress: () => const DeveloperOptionsRoute().push(context),
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
        ],
      ),
    );
  }
}
