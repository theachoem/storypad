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
      body: ListView.builder(
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
