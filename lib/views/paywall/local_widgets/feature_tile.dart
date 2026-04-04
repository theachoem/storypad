part of '../paywall_view.dart';

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.viewModel,
    required this.feature,
    super.key,
  });

  final PaywallViewModel viewModel;
  final PaywallFeatureObject feature;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ValueListenableBuilder(
            valueListenable: viewModel.focusingFeatureNotifer,
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
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorFromDayService(context: context).get(feature.weekdayColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(feature.iconData, color: ColorFromDayService(context: context).getForeground()),
          ),
          title: Text(feature.title),
          subtitle: Text(feature.subtitle),
          trailing: const Icon(SpIcons.keyboardRight),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0).add(
            EdgeInsets.only(
              left: MediaQuery.of(context).padding.left,
              right: MediaQuery.of(context).padding.right,
            ),
          ),
          onTap: () async {
            final nextAction = await SpPaywallFeaturesSheet(
              params: PaywallFeaturesRoute(
                features: viewModel.features ?? [],
                initialPage: viewModel.features?.indexWhere((element) => element.type == feature.type) ?? 0,
              ),
            ).show(context: context);

            if (context.mounted && nextAction is PaywallFeatureNextAction) {
              nextAction.action.call(context);

              if (nextAction.focusFeature != null) {
                viewModel.focusOn(nextAction.focusFeature!.type);
              }
            }
          },
        ),
      ],
    );
  }
}

class PaywallFeatureNextAction {
  final Future<void> Function(BuildContext) action;
  final PaywallFeatureObject? focusFeature;

  PaywallFeatureNextAction({
    required this.action,
    required this.focusFeature,
  });
}
