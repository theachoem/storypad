import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:storypad/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extensions.dart';
import 'package:storypad/routes/base_route.dart';
import 'package:storypad/views/assets/show/show_asset_view.dart';

import 'assets_view_model.dart';

part 'assets_adaptive.dart';

class AssetsRoute extends BaseRoute {
  AssetsRoute();

  @override
  Widget buildPage(BuildContext context) => AssetsView(params: this);

  @override
  bool get preferredNestedRoute => true;
}

class AssetsView extends StatelessWidget {
  const AssetsView({
    super.key,
    required this.params,
  });

  final AssetsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<AssetsViewModel>(
      create: (context) => AssetsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _AssetsAdaptive(viewModel);
      },
    );
  }
}
