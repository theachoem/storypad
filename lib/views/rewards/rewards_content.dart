part of 'rewards_view.dart';

class _RewardsContent extends StatelessWidget {
  const _RewardsContent(this.viewModel);

  final RewardsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final currentReward = Provider.of<InAppPurchaseProvider>(context).currentReward;
    final addOnRewards = RewardObject.rewards.where((reward) => reward.purchaseCount > 0).toList();

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
                  currentReward.rewardedTitle,
                  style: TextTheme.of(context).titleLarge,
                  textAlign: .center,
                ),
                const SizedBox(height: 4),
                Text(
                  currentReward.rewardedMessage,
                  style: TextTheme.of(context).bodyMedium,
                  textAlign: .center,
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
                        unlocked: currentReward.purchaseCount >= reward.purchaseCount,
                      ),
                    );
                  } else {
                    return buildCard(
                      context: context,
                      reward: reward,
                      unlocked: currentReward.purchaseCount >= reward.purchaseCount,
                    );
                  }
                },
              ),
            ),
          ),
          for (int i = 0; i < addOnRewards.length; i++) ...[
            const SizedBox(height: 16),
            SpSectionTitle(
              title: [
                '${addOnRewards[i].purchaseCount}',
                '${addOnRewards[i].purchaseCount > 1 ? 'Purchases' : 'Purchase'} Rewards',
              ].join(' '),
            ),
            for (int j = 0; j < addOnRewards[i].features.length; j++) ...[
              buildRewardTile(
                context: context,
                title: addOnRewards[i].features[j].title,
                subtitle: addOnRewards[i].features[j].description,
                leadingIcon: addOnRewards[i].features[j].iconData,
                leadingDayColor: ((i + j) + 1) % 7,
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
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ColorFromDayService(context: context).get(leadingDayColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(leadingIcon, color: ColorFromDayService(context: context).getForeground()),
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
    required bool unlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
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
            child: unlocked
                ? Icon(SpIcons.verifiedFilled, color: ColorScheme.of(context).primary)
                : const Icon(SpIcons.lock),
          ),
        ],
      ),
    );
  }
}
