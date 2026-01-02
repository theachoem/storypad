part of 'rewards_view.dart';

class _RewardsContent extends StatelessWidget {
  const _RewardsContent(this.viewModel);

  final RewardsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);
    final currentReward = iapProvider.currentReward;

    List<RewardObject> addOnRewards = iapProvider.rewards.where((reward) => reward.purchaseCount > 0).toList();
    List<RewardObject> selectedAddOnRewards = viewModel.selectedRewardIndex != null
        ? [addOnRewards[viewModel.selectedRewardIndex!]]
        : addOnRewards;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      floatingActionButtonLocation: .centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: ColorScheme.of(context).primary,
        foregroundColor: ColorScheme.of(context).onPrimary,
        shape: const StadiumBorder(),
        label: Text(tr('button.get_add_ons')),
        icon: const Icon(SpIcons.addOns),
        onPressed: () {
          if (viewModel.params.fromAddOnsView) {
            Navigator.maybePop(context);
          } else {
            const AddOnsRoute(fromRewardsView: true).push(context);
          }
        },
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsetsGeometry.only(
              bottom: MediaQuery.paddingOf(context).bottom + kToolbarHeight + 96.0,
            ),
            children: [
              _RewardsHeader(currentReward: currentReward),
              if (addOnRewards.length > 1) ...[
                const SizedBox(height: 16),
                buildPurchaseCards(context, addOnRewards, currentReward),
              ] else ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
              ],
              for (int i = 0; i < selectedAddOnRewards.length; i++) ...[
                if (addOnRewards.length > 1) ...[
                  const SizedBox(height: 16),
                  SpSectionTitle(
                    title: [
                      '${selectedAddOnRewards[i].purchaseCount}',
                      (selectedAddOnRewards[i].purchaseCount > 1 ? tr('general.purchases') : tr('general.purchase')),
                    ].join(' '),
                  ),
                ],
                for (int j = 0; j < selectedAddOnRewards[i].features.length; j++) ...[
                  _RewardTile(
                    viewModel: viewModel,
                    feature: selectedAddOnRewards[i].features[j],
                    rewarded: currentReward.includedRewardedFeatures.contains(selectedAddOnRewards[i].features[j].type),
                  ),
                ],
              ],
            ],
          ),
          buildGradientBgOverlay(context),
        ],
      ),
    );
  }

  Widget buildPurchaseCards(
    BuildContext context,
    List<RewardObject> addOnRewards,
    RewardObject currentReward,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.paddingOf(context).left + 16.0,
        right: MediaQuery.paddingOf(context).right + 16.0,
      ),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        children: List.generate(
          addOnRewards.length,
          (index) {
            final reward = addOnRewards[index];

            if (index == addOnRewards.length - 1) {
              return StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: _PurchaseCard(
                  viewModel: viewModel,
                  reward: reward,
                  rewarded: currentReward.purchaseCount >= reward.purchaseCount,
                  index: index,
                ),
              );
            } else {
              return _PurchaseCard(
                viewModel: viewModel,
                reward: reward,
                rewarded: currentReward.purchaseCount >= reward.purchaseCount,
                index: index,
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildGradientBgOverlay(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: kToolbarHeight + 16.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: .topCenter,
            end: .bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
      ),
    );
  }
}
