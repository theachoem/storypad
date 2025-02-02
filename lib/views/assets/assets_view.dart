import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/env.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extensions.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/routes/base_route.dart';
import 'package:storypad/views/assets/show/show_asset_view.dart';
import 'package:storypad/widgets/custom_embed/sp_image.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

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
