part of '../languages_view.dart';

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.readOnly.surface2,
      contentTextStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
      padding: const EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0).add(
        EdgeInsets.only(
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right,
        ),
      ),
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
