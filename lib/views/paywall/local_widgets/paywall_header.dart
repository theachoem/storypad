part of '../paywall_view.dart';

class _PaywallHeader extends StatelessWidget {
  const _PaywallHeader();

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);

    return Container(
      padding: EdgeInsets.only(
        left: MediaQuery.paddingOf(context).left + 32.0,
        right: MediaQuery.paddingOf(context).right + 32.0,
      ),
      alignment: .center,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        child: Column(
          children: [
            SpFirestoreStorageDownloaderBuilder(
              filePath: '/icons/hand_drawn/hand_drawn_diary_56x56.png',
              builder: (context, file, failed) {
                if (file == null) {
                  return SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(child: failed ? const Icon(Icons.error) : null),
                  );
                }
                return SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.file(
                    file,
                    cacheWidth: (56 * MediaQuery.of(context).devicePixelRatio).round(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              tr("page.paywall.title"),
              style: TextTheme.of(context).titleLarge,
              textAlign: .center,
            ),
            const SizedBox(height: 4),
            Text(
              iapProvider.isProUser
                  ? tr("page.paywall.messages.thank_you_pro_user")
                  : tr("page.paywall.messages.unlock_all_features"),
              style: TextTheme.of(context).bodyMedium,
              textAlign: .center,
            ),
            if (iapProvider.isProUser) ...[
              const SizedBox(height: 8),
              const SpProBadge(),
            ],
          ],
        ),
      ),
    );
  }
}
