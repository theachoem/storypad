import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/paywall_feature_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/paywall/features/paywall_features_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/bottom_sheets/sp_android_redemption_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_paywall_features_sheet.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'paywall_view_model.dart';

part 'paywall_content.dart';
part 'local_widgets/paywall_header.dart';
part 'local_widgets/feature_tile.dart';

class PaywallRoute extends BaseRoute {
  const PaywallRoute({
    this.initialFocus,
  });

  final PaywallFeature? initialFocus;

  @override
  Widget buildPage(BuildContext context) => PaywallView(params: this);
}

class PaywallView extends StatelessWidget {
  const PaywallView({
    super.key,
    required this.params,
  });

  final PaywallRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<PaywallViewModel>(
      create: (context) => PaywallViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _PaywallContent(viewModel);
      },
    );
  }
}
