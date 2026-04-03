import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

import 'paywall_view_model.dart';

part 'paywall_content.dart';

enum PaywallFeatures {
  relaxSounds,
  voiceJournal,
  markdownExport,
  pinnedNotes,
  templates,
  writingStats,
  backgrounds,
}

class PaywallRoute extends BaseRoute {
  const PaywallRoute({
    this.initialFocus,
  });

  final PaywallFeatures? initialFocus;

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
      create: (context) => PaywallViewModel(params: params),
      builder: (context, viewModel, child) {
        return _PaywallContent(viewModel);
      },
    );
  }
}
