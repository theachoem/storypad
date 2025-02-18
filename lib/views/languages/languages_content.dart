part of 'languages_view.dart';

class _LanguagesContent extends StatelessWidget {
  const _LanguagesContent(this.viewModel);

  final LanguagesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: _FeedbackBanner(context: context),
      body: ListView.builder(
        padding: EdgeInsets.only(bottom: 16.0),
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
      title: Text(kNativeLanguageNames[locale.toLanguageTag()]!),
      trailing: Visibility(
        visible: selected,
        child: SpFadeIn.fromBottom(
          child: const Icon(Icons.check),
        ),
      ),
      onTap: () {
        context.setLocale(viewModel.supportedLocales.elementAt(index));
        AnalyticsService.instance.logSetLocale(
          newLocale: viewModel.supportedLocales.elementAt(index),
        );
      },
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
      padding: EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0),
      leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface),
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, top: 4.0),
      child: OutlinedButton.icon(
        icon: Icon(Icons.fact_check_outlined),
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
