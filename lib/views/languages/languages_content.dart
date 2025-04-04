part of 'languages_view.dart';

class _LanguagesContent extends StatelessWidget {
  const _LanguagesContent(this.viewModel);

  final LanguagesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (viewModel.canSetToDeviceLocale)
            IconButton(
              tooltip: tr("button.reset"),
              icon: const Icon(SpIcons.refresh),
              onPressed: () => viewModel.useDeviceLocale(context),
            ),
        ],
      ),
      bottomNavigationBar: viewModel.params.showBetaBanner ? _FeedbackBanner(context: context) : null,
      floatingActionButton: viewModel.params.showThemeFAB
          ? FloatingActionButton(
              child: const Icon(SpIcons.theme),
              onPressed: () => ThemeRoute(fromOnboarding: viewModel.params.fromOnboarding).push(context))
          : null,
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16.0),
        itemCount: viewModel.supportedLocales.length,
        itemBuilder: (context, index) {
          return buildLocaleTile(index, context);
        },
      ),
    );
  }

  Widget buildLocaleTile(int index, BuildContext context) {
    final locale = viewModel.supportedLocales.elementAt(index);
    bool selected = context.locale.toLanguageTag() == locale.toLanguageTag();

    return ListTile(
      key: viewModel.supportedLocaleKeys[index],
      title: Text(kNativeLanguageNames[locale.toLanguageTag()]!),
      trailing: Visibility(
        visible: selected,
        child: SpFadeIn.fromBottom(
          child: const Icon(SpIcons.check),
        ),
      ),
      subtitle: viewModel.isSystemLocale(locale) ? Text(tr('general.default')) : null,
      onTap: () => viewModel.setLocale(locale, context),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.readOnly.surface2,
      contentTextStyle:
          Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
      padding: const EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0).add(EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
      )),
      leading: Icon(SpIcons.info, color: Theme.of(context).colorScheme.onSurface),
      content: Text(
        tr('list_tile.ask_for_locale_suggestion.subtitle'),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      forceActionsBelow: true,
      actions: [
        buildSuggestButton(context),
      ],
    );
  }

  Widget buildSuggestButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        top: 4.0,
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
      ),
      child: OutlinedButton.icon(
        icon: const Icon(SpIcons.factCheck),
        label: Text(
          tr('button.suggest'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        onPressed: () {
          UrlOpenerService.openInCustomTab(context, RemoteConfigService.localizationSupportUrl.get());
        },
      ),
    );
  }
}
