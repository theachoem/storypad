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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      floatingActionButtonLocation: .centerDocked,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        shape: const StadiumBorder(),
        label: Text(tr('button.browse_add_ons')),
        icon: const Icon(SpIcons.addOns),
        onPressed: () => const AddOnsRoute().push(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsetsGeometry.only(
              bottom: MediaQuery.paddingOf(context).bottom + kToolbarHeight + 16.0,
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
                          child: Image.file(file),
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
                    (selectedAddOnRewards[i].purchaseCount > 1 ? tr('general.purchases') : tr('general.purchase')),
                  ].join(' '),
                ),
                for (int j = 0; j < selectedAddOnRewards[i].features.length; j++) ...[
                  buildRewardTile(
                    context: context,
                    title: selectedAddOnRewards[i].features[j].title,
                    subtitle: selectedAddOnRewards[i].features[j].subtitle,
                    leadingIcon: selectedAddOnRewards[i].features[j].iconData,
                    leadingDayColor: selectedAddOnRewards[i].features[j].dayColor,
                    videoUrlPath: selectedAddOnRewards[i].features[j].videoUrlPath,
                    rewarded: currentReward.includedRewardedFeatures.contains(selectedAddOnRewards[i].features[j].type),
                    type: selectedAddOnRewards[i].features[j].type,
                  ),
                ],
              ],
            ],
          ),
          Positioned(
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
          ),
        ],
      ),
    );
  }

  Widget buildRewardTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String videoUrlPath,
    required IconData leadingIcon,
    required RewardFeature type,
    required int leadingDayColor,
    required bool rewarded,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder(
            valueListenable: viewModel.focusingRewardFeature,
            builder: (context, focusingRewardFeature, child) {
              return AnimatedContainer(
                duration: Durations.long4,
                color: focusingRewardFeature == type ? ColorScheme.of(context).readOnly.surface5 : Colors.transparent,
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
        ListTile(
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
          onTap: () {
            SpVideoDemoSheet.showVideoSheet(
              context: context,
              videoUrlPath: videoUrlPath,
              demoTitle: title,
              demoSubtitle: subtitle,
            );
          },
        ),
      ],
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
              reward.purchaseCount > 1 ? tr('general.purchases') : tr('general.purchase'),
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
