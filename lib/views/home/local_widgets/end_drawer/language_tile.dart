part of 'home_end_drawer.dart';

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => LanguagesRoute().push(context),
      leading: const Icon(Icons.language),
      subtitle: Text(kNativeLanguageNames[context.locale.toLanguageTag()]!),
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
    );
  }
}
