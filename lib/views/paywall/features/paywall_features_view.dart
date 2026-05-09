import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/paywall_feature_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_demo_images.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_page_indicator.dart';
import 'package:storypad/widgets/sp_page_view.dart';

import 'paywall_features_view_model.dart';

part 'paywall_features_content.dart';

class PaywallFeaturesRoute extends BaseRoute {
  const PaywallFeaturesRoute({
    required this.features,
    required this.initialPage,
  });

  final List<PaywallFeatureObject> features;
  final int initialPage;

  @override
  Widget buildPage(BuildContext context) => PaywallFeaturesView(params: this);
}

class PaywallFeaturesView extends StatelessWidget {
  const PaywallFeaturesView({
    super.key,
    required this.params,
  });

  final PaywallFeaturesRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaywallFeaturesViewModel>(
      create: (context) => PaywallFeaturesViewModel(params: params),
      builder: (context, child) {
        return _PaywallFeaturesContent(Provider.of(context));
      },
    );
  }
}
