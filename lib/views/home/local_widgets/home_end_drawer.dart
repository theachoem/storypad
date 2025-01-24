part of '../home_view.dart';

const bool _enableSwitchLanguage = false;

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
          if (kDebugMode) buildGoogleDriveRequestsCount(context),
          const Divider(height: 1),
          const SizedBox(height: 8.0),
          buildSearchTile(context),
          buildTagsTile(context),
          buildArchiveBinTile(context),
          const Divider(),
          const BackupTile(),
          const Divider(),
          buildThemeTile(context),
          if (_enableSwitchLanguage) buildLanguageTile(context),
          buildBiometricsTile(),
        ],
      ),
    );
  }

  Widget buildSearchTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: const Text('Search'),
      onTap: () {
        SearchRoute().push(context);
      },
    );
  }

  Widget buildTagsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sell_outlined),
      title: const Text('Tags'),
      onTap: () => TagsRoute().push(context),
    );
  }

  Widget buildArchiveBinTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.archive_outlined),
      title: const Text('Archives / Bin'),
      onTap: () => ArchivesRoute().push(context),
    );
  }

  Widget buildThemeTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.color_lens_outlined),
      title: const Text('Theme'),
      onTap: () => ThemeRoute().push(context),
    );
  }

  Widget buildLanguageTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text("Language"),
      subtitle: const Text("Khmer"),
      onTap: () => const _LanguagesRoute().push(context),
    );
  }

  Widget buildBiometricsTile() {
    return Consumer<LocalAuthProvider>(
      builder: (context, provider, child) {
        return Visibility(
          visible: provider.canCheckBiometrics,
          child: SwitchListTile.adaptive(
            secondary: const Icon(Icons.lock),
            title: const Text('Biometrics Lock'),
            value: provider.localAuthEnabled,
            onChanged: (value) => provider.setEnable(value),
          ),
        );
      },
    );
  }

  Widget buildGoogleDriveRequestsCount(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(color: ColorScheme.of(context).bootstrap.info.color),
      child: Text(
        '${GoogleDriveService.instance.requestCount} Google Drive requests (debug only)',
        textAlign: TextAlign.center,
        style: TextTheme.of(context).bodySmall?.copyWith(color: ColorScheme.of(context).bootstrap.info.onColor),
      ),
    );
  }
}

class _LanguagesRoute extends StatelessWidget {
  const _LanguagesRoute();

  Future<T?> push<T extends Object?>(BuildContext context) {
    return SpNestedNavigation.maybeOf(context)!.push(this);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    Iterable<Locale> supportedLocales = context.findAncestorWidgetOfExactType<MaterialApp>()?.supportedLocales ?? [];

    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: supportedLocales.length,
        itemBuilder: (context, index) {
          bool selected = themeProvider.currentLocale?.languageCode == supportedLocales.elementAt(index).languageCode;

          return ListTile(
            title: Text(supportedLocales.elementAt(index).languageCode.toUpperCase()),
            trailing: Visibility(
              visible: selected,
              child: SpFadeIn.fromBottom(
                child: const Icon(Icons.check),
              ),
            ),
            onTap: () {
              context.read<ThemeProvider>().setCurrentLocale(supportedLocales.elementAt(index));
            },
          );
        },
      ),
    );
  }
}
