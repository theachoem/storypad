part of 'languages_view.dart';

class _LanguagesContent extends StatelessWidget {
  const _LanguagesContent(this.viewModel);

  final LanguagesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    List<Locale> supportedLocales =
        context.findAncestorWidgetOfExactType<MaterialApp>()?.supportedLocales.toList() ?? [];

    // en_US
    String? languageCode = Intl.systemLocale.split("_").firstOrNull;
    supportedLocales.sort((a, b) {
      if (a.languageCode == languageCode) {
        return -1;
      } else if (a.languageCode == languageCode) {
        return 1;
      } else {
        return a.languageCode.compareTo(b.languageCode);
      }
    });

    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        contentTextStyle:
            Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
        padding: EdgeInsetsDirectional.only(
          start: 16.0,
          top: 24.0,
          end: 16.0,
          bottom: 4.0,
        ),
        leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSecondary),
        content: Text("Help improve translations or request a language on GitHub!"),
        forceActionsBelow: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: OutlinedButton(
              child: Text(
                "OPEN GITHUB",
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
              onPressed: () {
                UrlOpenerService.openInCustomTab(context, RemoteConfigService.localizationSupportUrl.get());
              },
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(bottom: 16.0),
        itemCount: supportedLocales.length,
        itemBuilder: (context, index) {
          final locale = supportedLocales.elementAt(index);
          bool selected = context.locale.toLanguageTag() == locale.toLanguageTag();

          return ListTile(
            title: Text(AppLocale.getLanguageNativeName(locale)),
            trailing: Visibility(
              visible: selected,
              child: SpFadeIn.fromBottom(
                child: const Icon(Icons.check),
              ),
            ),
            onTap: () {
              context.setLocale(supportedLocales.elementAt(index));

              AnalyticsService.instance.logSetLocale(
                newLocale: supportedLocales.elementAt(index),
              );
            },
          );
        },
      ),
    );
  }
}
