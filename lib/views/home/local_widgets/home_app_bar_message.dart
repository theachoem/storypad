part of '../home_view.dart';

class _HomeAppBarMessage extends StatelessWidget {
  const _HomeAppBarMessage();

  @override
  Widget build(BuildContext context) {
    BackupProvider backupProvider = Provider.of<BackupProvider>(context);

    String? title;
    Widget? trailing;

    bool syncing = backupProvider.syncing;
    Widget child = Text(
      WelcomeMessageService.get(context),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextTheme.of(context).bodyLarge,
    );

    bool showWelcomeMessage = true;

    if (syncing == true) {
      showWelcomeMessage = false;
      title = "${tr("page.home.app_bar.messages.we_syncing_ur_data")} ";
      trailing = Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: const SizedBox.square(
          dimension: 12.0,
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    } else {
      showWelcomeMessage = true;
      title = null;
      trailing = null;
    }

    return SpCrossFade(
      duration: Durations.medium3,
      alignment: Alignment.topLeft,
      showFirst: showWelcomeMessage,
      firstChild: child,
      secondChild: RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: TextTheme.of(context).bodyLarge,
          text: title,
          children: trailing == null ? null : [WidgetSpan(alignment: PlaceholderAlignment.middle, child: trailing)],
        ),
      ),
    );
  }
}
