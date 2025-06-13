import 'package:flutter/cupertino.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/gen/assets.gen.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

import 'paywalls_view_model.dart';

part 'paywalls_content.dart';
part 'local_widgets/offers.dart';

class PaywallsRoute extends BaseRoute {
  const PaywallsRoute();

  @override
  bool get fullscreenDialog => true;

  @override
  Widget buildPage(BuildContext context) => PaywallsView(params: this);
}

class PaywallsView extends StatelessWidget {
  const PaywallsView({
    super.key,
    required this.params,
  });

  final PaywallsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<PaywallsViewModel>(
      create: (context) => PaywallsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _PaywallsContent(viewModel);
      },
    );
  }
}
