part of '../home_view.dart';

class _HomeAppBarMessage extends StatelessWidget {
  const _HomeAppBarMessage();

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupProvider>(
      child: Text(
        tr('page.home.app_bar.messages.what_in_ur_mind'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextTheme.of(context).bodyLarge,
      ),
      builder: (context, provider, child) {
        String? title;
        Widget? trailing;

        bool showWelcomeMessage = true;

        if (provider.syncing) {
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
          // title = "${tr("page.home.app_bar.messages.ready_to_syn_data")} ";
          // trailing = Container(
          //   margin: const EdgeInsets.symmetric(horizontal: 4.0),
          //   child: const Icon(
          //     Icons.cloud_off,
          //     size: 16.0,
          //   ),
          // );
          showWelcomeMessage = true;
          title = null;
          trailing = null;
        }

        return SpCrossFade(
          duration: Durations.medium3,
          alignment: Alignment.topLeft,
          showFirst: showWelcomeMessage,
          firstChild: child!,
          secondChild: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: TextTheme.of(context).bodyLarge,
              text: title,
              children: trailing == null ? null : [WidgetSpan(alignment: PlaceholderAlignment.middle, child: trailing)],
            ),
          ),
        );
      },
    );
  }
}
