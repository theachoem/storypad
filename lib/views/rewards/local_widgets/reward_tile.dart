part of '../rewards_view.dart';

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.viewModel,
    required this.feature,
    required this.rewarded,
  });

  final RewardsViewModel viewModel;
  final RewardFeatureObject feature;
  final bool rewarded;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder(
            valueListenable: viewModel.focusingRewardFeature,
            builder: (context, focusingRewardFeature, child) {
              return AnimatedContainer(
                duration: Durations.long4,
                color: focusingRewardFeature == feature.type
                    ? ColorScheme.of(context).readOnly.surface5
                    : Colors.transparent,
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
                  color: ColorFromDayService(context: context).get(feature.dayColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(feature.iconData, color: ColorFromDayService(context: context).getForeground()),
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
          title: Text(feature.title),
          subtitle: Text(feature.subtitle),
          trailing: const Icon(Icons.play_circle_outlined),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0).add(
            EdgeInsets.only(
              left: MediaQuery.of(context).padding.left,
              right: MediaQuery.of(context).padding.right,
            ),
          ),
          onTap: () {
            SpVideoDemoSheet.showVideoSheet(
              context: context,
              videoUrlPath: feature.videoUrlPath,
              demoTitle: feature.title,
              demoSubtitle: feature.subtitle,
              demoBackgroundColor: ColorFromDayService(context: context).get(feature.dayColor),
              demoWidth: 270,
              demoAspectRatio: 0.4596888260254597,
            );
          },
        ),
      ],
    );
  }
}
