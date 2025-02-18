part of '../home_view.dart';

class _HomeEndDrawer extends StatelessWidget {
  const _HomeEndDrawer(this.viewModel);

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Drawer(child: ScaffoldMessenger(
      child: Scaffold(
        body: SpEndDrawerTheme(
          child: SpNestedNavigation(
            initialScreen: Builder(builder: (childContext) {
              return buildDrawer(
                context: childContext,
                closeDrawer: () => Navigator.of(context).pop(),
              );
            }),
          ),
        ),
      ),
    ));
  }

  Widget buildDrawer({
    required BuildContext context,
    required void Function() closeDrawer,
  }) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        actions: const [
          _MoreOptionsButton(),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        children: [
          const _HomeEndDrawerHeader(),
          const Divider(height: 1),
          const SizedBox(height: 8.0),
          buildSearchTile(context),
          buildTagsTile(context),
          buildArchiveBinTile(context),
          if (kStoryPad)
            ListTile(
              leading: const Icon(Icons.photo_album_outlined),
              title: Text(tr("page.library.title")),
              onTap: () => AssetsRoute().push(context),
            ),
          const Divider(),
          const BackupTile(),
          const Divider(),
          buildThemeTile(context),
          buildLanguageTile(context),
          buildBiometricsTile(),
          if (RemoteConfigService.communityUrl.get().trim().isNotEmpty == true) ...[
            const Divider(),
            buildCommunityTile(context),
          ],
        ],
      ),
    );
  }

  Widget buildCommunityTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.forum_outlined),
      title: Text(tr("list_tile.community.title")),
      onTap: () async {
        UrlOpenerService.openInCustomTab(
          context,
          RemoteConfigService.communityUrl.get(),
          prefersDeepLink: true,
        );
      },
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

  Widget buildLanguageTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          text: "${tr("page.language.title")} ",
          children: [
            WidgetSpan(
              child: Material(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                color: ColorScheme.of(context).bootstrap.success.color,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.textScalerOf(context).scale(6),
                    vertical: MediaQuery.textScalerOf(context).scale(1),
                  ),
                  child: Text(
                    tr('general.beta'),
                    style: TextTheme.of(context)
                        .labelMedium
                        ?.copyWith(color: ColorScheme.of(context).bootstrap.success.onColor),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      subtitle: Text(kNativeLanguageNames[context.locale.toLanguageTag()]!),
      onTap: () => LanguagesRoute().push(context),
    );
  }

  Widget buildBiometricsTile() {
    return Consumer<LocalAuthProvider>(
      builder: (context, provider, child) {
        return Visibility(
          visible: provider.canCheckBiometrics,
          child: SwitchListTile.adaptive(
            secondary: const Icon(Icons.lock),
            title: Text(tr("list_tile.biometrics_lock.title")),
            value: provider.localAuthEnabled,
            onChanged: (value) => provider.setEnable(value),
          ),
        );
      },
    );
  }
}
