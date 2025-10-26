part of 'gallery_tab.dart';

class _LicenseText extends StatelessWidget {
  const _LicenseText();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 16.0,
        left: MediaQuery.of(context).padding.left + 16.0,
        right: MediaQuery.of(context).padding.right + 16.0,
      ),
      child: buildText(context),
    );
  }

  Widget buildText(BuildContext context) {
    Color foregroundColor = ColorScheme.of(context).onSurface;
    return SpTapEffect(
      effects: [SpTapEffectType.touchableOpacity],
      onTap: () => showLicenseDialog(context),
      child: RichText(
        textAlign: TextAlign.center,
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          children: [
            WidgetSpan(
              child: Container(
                margin: EdgeInsets.only(right: MediaQuery.textScalerOf(context).scale(4.0)),
                child: Icon(
                  SpIcons.license,
                  size: MediaQuery.textScalerOf(context).scale(16.0),
                  color: foregroundColor,
                ),
              ),
            ),
            TextSpan(
              text: tr("list_tile.licenses.title"),
              style: TextTheme.of(context).titleMedium?.copyWith(
                color: foregroundColor,
                decorationColor: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showLicenseDialog(BuildContext context) {
    return showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog.adaptive(
          content: MarkdownBody(
            listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
            styleSheet: MarkdownStyleSheet(
              p: TextTheme.of(context).bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              a: TextTheme.of(context).bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                decorationColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                decoration: TextDecoration.underline,
              ),
            ),
            data: tr(
              'general.icons_credit',
              namedArgs: {
                'ICON_LINK': '[freepik.com](https://www.freepik.com/author/juicy-fish/icons/juicy-fish-sketchy_908)',
              },
            ),
            onTapLink: (text, href, title) => UrlOpenerService.openForMarkdown(
              context: context,
              text: text,
              href: href,
              title: title,
            ),
          ),
        );
      },
    );
  }
}
