import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/types/feature_reward.dart';
import 'rewards_view.dart';

class RewardsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final RewardsRoute params;
  late final ValueNotifier<RewardFeature?> focusingRewardFeature = ValueNotifier(params.initialFocusedRewardFeature);

  RewardsViewModel({
    required this.params,
  }) {
    if (focusingRewardFeature.value != null) {
      Future.delayed(Durations.long4, () {
        if (!disposed) focusingRewardFeature.value = null;
      });
    }
  }

  int? selectedRewardIndex;

  void toggleRewardAtIndex(int index) {
    if (index == selectedRewardIndex) {
      selectedRewardIndex = null;
      notifyListeners();
    } else {
      selectedRewardIndex = index;
      notifyListeners();
    }
  }
}
