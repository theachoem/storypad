import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/extensions/matrix_4_extension.dart';
import 'package:storypad/core/objects/reward_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/types/feature_reward.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_video_demo_sheet.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'rewards_view_model.dart';

part 'rewards_content.dart';
part 'local_widgets/rewards_header.dart';
part 'local_widgets/purchase_card.dart';
part 'local_widgets/reward_tile.dart';

class RewardsRoute extends BaseRoute {
  const RewardsRoute({
    this.initialFocusedRewardFeature,
  });

  final RewardFeature? initialFocusedRewardFeature;

  @override
  Widget buildPage(BuildContext context) => RewardsView(params: this);
}

class RewardsView extends StatelessWidget {
  const RewardsView({
    super.key,
    required this.params,
  });

  final RewardsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<RewardsViewModel>(
      create: (context) => RewardsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _RewardsContent(viewModel);
      },
    );
  }
}
