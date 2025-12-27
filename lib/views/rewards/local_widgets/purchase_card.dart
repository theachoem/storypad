part of '../rewards_view.dart';

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.viewModel,
    required this.reward,
    required this.rewarded,
    required this.index,
  });

  final RewardsViewModel viewModel;
  final RewardObject reward;
  final bool rewarded;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      effects: [.scaleDown],
      onTap: () => viewModel.toggleRewardAtIndex(index),
      child: AnimatedContainer(
        duration: Durations.short2,
        curve: Curves.ease,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: rewarded ? ColorScheme.of(context).primary.withValues(alpha: 0.08) : ColorScheme.of(context).surface,
          border: Border.all(
            color: viewModel.selectedRewardIndex == index
                ? ColorScheme.of(context).primary
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: .start,
          crossAxisAlignment: .start,
          children: [
            Text.rich(
              TextSpan(
                text: min(context.read<InAppPurchaseProvider>().purchaseCount, reward.purchaseCount).toString(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: ColorScheme.of(context).primary),
                children: [
                  TextSpan(
                    text: '/${reward.purchaseCount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColorScheme.of(context).primary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              reward.purchaseCount > 1 ? tr('general.purchases') : tr('general.purchase'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: rewarded ? ColorScheme.of(context).onSurface : null,
              ),
            ),
            Align(
              alignment: .bottomRight,
              child: rewarded
                  ? Icon(SpIcons.verifiedFilled, color: ColorScheme.of(context).primary)
                  : const Icon(SpIcons.lock),
            ),
          ],
        ),
      ),
    );
  }
}
