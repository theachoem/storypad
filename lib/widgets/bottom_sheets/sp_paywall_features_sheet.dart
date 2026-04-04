import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/views/paywall/features/paywall_features_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';

class SpPaywallFeaturesSheet extends BaseBottomSheet {
  SpPaywallFeaturesSheet({
    required this.params,
  });

  final PaywallFeaturesRoute params;

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return buildView();
    } else {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildView(),
          );
        },
      );
    }
  }

  PaywallFeaturesView buildView() => PaywallFeaturesView(params: params);
}
