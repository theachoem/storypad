import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'templates_view_model.dart';

part 'templates_content.dart';

class TemplatesRoute extends BaseRoute {
  const TemplatesRoute();

  @override
  Widget buildPage(BuildContext context) => TemplatesView(params: this);
}

class TemplatesView extends StatelessWidget {
  const TemplatesView({
    super.key,
    required this.params,
  });

  final TemplatesRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<TemplatesViewModel>(
      create: (context) => TemplatesViewModel(params: params),
      builder: (context, viewModel, child) {
        return _TemplatesContent(viewModel);
      },
    );
  }
}
