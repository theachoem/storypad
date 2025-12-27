part of 'rewards_view.dart';

class _RewardsContent extends StatelessWidget {
  const _RewardsContent(this.viewModel);

  final RewardsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final iapProvider = Provider.of<InAppPurchaseProvider>(context);
    final currentReward = iapProvider.currentReward;

    List<RewardObject> addOnRewards = iapProvider.rewards.where((reward) => reward.purchaseCount > 0).toList();
    List<RewardObject> selectedAddOnRewards = viewModel.selectecedRewardIndex != null
        ? [addOnRewards[viewModel.selectecedRewardIndex!]]
        : addOnRewards;

    bool allRewarded = currentReward.features.length == iapProvider.rewards.last.features.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: .min,
        children: [
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: FilledButton(
              child: const Text('Browse Add-Ons'),
              onPressed: () => const AddOnsRoute().push(context),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsetsGeometry.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.paddingOf(context).left + 32.0,
              right: MediaQuery.paddingOf(context).right + 32.0,
            ),
            child: Column(
              children: [
                SpFirestoreStorageDownloaderBuilder(
                  filePath: '/icons/hand_drawn/hand_drawn_sun_56x56.png',
                  builder: (context, file, failed) {
                    if (file == null) {
                      return SizedBox(
                        width: 88,
                        height: 88,
                        child: Center(child: failed ? const Icon(Icons.error) : null),
                      );
                    }
                    return Image.file(
                      file,
                      width: 88,
                      height: 88,
                    );
                  },
                ),
                Text(
                  'Rewards',
                  style: TextTheme.of(context).titleLarge,
                  textAlign: .center,
                ),
                const SizedBox(height: 4),
                Text(
                  allRewarded
                      ? 'You have unlocked all rewards! Thank you for supporting StoryPad development!'
                      : 'Purchase add-ons to unlock extra features & support StoryPad development!',
                  style: TextTheme.of(context).bodyMedium,
                  textAlign: .center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorScheme.of(context).primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(currentReward.rewardedBadge),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
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
                      crossAxisCellCount: 2,
                      child: buildCard(
                        context: context,
                        reward: reward,
                        rewarded: currentReward.purchaseCount >= reward.purchaseCount,
                        index: index,
                      ),
                    );
                  } else {
                    return buildCard(
                      context: context,
                      reward: reward,
                      rewarded: currentReward.purchaseCount >= reward.purchaseCount,
                      index: index,
                    );
                  }
                },
              ),
            ),
          ),
          for (int i = 0; i < selectedAddOnRewards.length; i++) ...[
            const SizedBox(height: 16),
            SpSectionTitle(
              title: [
                '${selectedAddOnRewards[i].purchaseCount}',
                '${selectedAddOnRewards[i].purchaseCount > 1 ? 'Purchases' : 'Purchase'} Rewards',
              ].join(' '),
            ),
            for (int j = 0; j < selectedAddOnRewards[i].features.length; j++) ...[
              buildRewardTile(
                context: context,
                title: selectedAddOnRewards[i].features[j].title,
                subtitle: selectedAddOnRewards[i].features[j].description,
                leadingIcon: selectedAddOnRewards[i].features[j].iconData,
                leadingDayColor: selectedAddOnRewards[i].features[j].dayColor,
                rewarded: currentReward.includedRewardedFeatures.contains(selectedAddOnRewards[i].features[j].type),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget buildRewardTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required int leadingDayColor,
    required bool rewarded,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorFromDayService(context: context).get(leadingDayColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(leadingIcon, color: ColorFromDayService(context: context).getForeground()),
          ),
          if (!rewarded)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                transform: Matrix4.identity()..spTranslate(8.0, 8.0),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).surface,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock,
                  size: 16,
                  color: ColorScheme.of(context).onSurface,
                ),
              ),
            ),
        ],
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.play_circle_outlined),
      onTap: () {},
    );
  }

  Widget buildCard({
    required BuildContext context,
    required RewardObject reward,
    required bool rewarded,
    required int index,
  }) {
    return SpTapEffect(
      effects: [.scaleDown],
      onTap: () => viewModel.toggleRewardAtIndex(index),
      child: AnimatedContainer(
        duration: Durations.short2,
        curve: Curves.ease,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: rewarded ? ColorScheme.of(context).primaryContainer : ColorScheme.of(context).surface,
          border: Border.all(
            color: viewModel.selectecedRewardIndex == index
                ? ColorScheme.of(context).primary
                : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: .start,
          crossAxisAlignment: .start,
          children: [
            Text(
              reward.purchaseCount.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: ColorScheme.of(context).primary),
            ),
            Text(
              reward.purchaseCount > 1 ? 'Purchases' : 'Purchase',
              style: Theme.of(context).textTheme.bodyMedium,
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
