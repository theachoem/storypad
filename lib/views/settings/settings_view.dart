import 'package:storypad/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/routes/base_route.dart';

import 'settings_view_model.dart';

part 'settings_adaptive.dart';

class SettingsRoute extends BaseRoute {
  SettingsRoute();

  @override
  Widget buildPage(BuildContext context) => SettingsView(params: this);

  @override
  bool get nestedRoute => true;
}

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.params,
  });

  final SettingsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<SettingsViewModel>(
      create: (context) => SettingsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _SettingsAdaptive(viewModel);
      },
    );
  }
}
