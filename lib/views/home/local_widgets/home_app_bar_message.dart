part of '../home_view.dart';

class _HomeAppBarMessage extends StatelessWidget {
  const _HomeAppBarMessage();

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupProvider>(
      child: Text(
        "What did you have in mind?",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextTheme.of(context).bodyLarge,
      ),
      builder: (context, provider, child) {
        String? title;
        Widget? trailing;

        bool showWelcomeMessage = provider.source.isSignedIn == true && provider.lastDbUpdatedAt == null ||
            provider.lastSyncedAt == null ||
            provider.synced;

        if (provider.syncing) {
          title = "We're syncing your data ";
          trailing = Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: const SizedBox.square(
              dimension: 12.0,
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        } else {
          title = "Ready to sync your data? ";
          trailing = Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: const Icon(
              Icons.cloud_off,
              size: 16.0,
            ),
          );
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
              children: [
                WidgetSpan(alignment: PlaceholderAlignment.middle, child: trailing),
              ],
            ),
          ),
        );
      },
    );
  }
}
