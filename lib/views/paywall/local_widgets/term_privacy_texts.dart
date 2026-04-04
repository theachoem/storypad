part of '../paywall_view.dart';

class _TermPrivacyTexts extends StatelessWidget {
  const _TermPrivacyTexts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 8.0,
        bottom: 16.0,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children:
            [
              (
                (tr('general.term_of_use')),
                () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/term-of-use'),
              ),
              ("•", null),
              (
                (tr('general.privacy_policy')),
                () => UrlOpenerService.openInCustomTab(context, 'https://storypad.me/privacy-policy'),
              ),
            ].map((link) {
              return SpTapEffect(
                onTap: link.$2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
                  child: Text(
                    link.$1,
                    style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).primary),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
