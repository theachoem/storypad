import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

import 'paywalls_view_model.dart';

part 'paywalls_content.dart';

class PaywallsRoute extends BaseRoute {
  const PaywallsRoute();

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
