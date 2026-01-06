part of '../rewards_view.dart';

class _RewardsHeader extends StatelessWidget {
  const _RewardsHeader({
    required this.currentReward,
  });

  final RewardObject currentReward;

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
              filePath: currentReward.rewardedIconPath,
              builder: (context, file, failed) {
                if (file == null) {
                  return SizedBox(
                    width: 88,
                    height: 88,
                    child: Center(child: failed ? const Icon(Icons.error) : null),
                  );
                }
                return SizedBox(
                  width: 88,
                  height: 88,
                  child: Image.file(
                    file,
                    cacheWidth: (88 * MediaQuery.of(context).devicePixelRatio).round(),
                  ),
                );
              },
            ),
            Text(
              tr('page.rewards.title'),
              style: TextTheme.of(context).titleLarge,
              textAlign: .center,
            ),
            const SizedBox(height: 4),
            Text(
              iapProvider.allRewarded
                  ? tr('page.rewards.message_all_rewards_unlocked')
                  : tr('page.rewards.message_default'),
              style: TextTheme.of(context).bodyMedium,
              textAlign: .center,
            ),
            if (currentReward.purchaseCount >= 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  currentReward.rewardedBadge,
                  style: TextStyle(
                    color: ColorScheme.of(context).onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
