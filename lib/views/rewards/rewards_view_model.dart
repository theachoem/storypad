import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'rewards_view.dart';

class RewardsViewModel extends ChangeNotifier with DisposeAwareMixin {
  final RewardsRoute params;

  RewardsViewModel({
    required this.params,
  });
}
