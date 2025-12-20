import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/widgets/sp_markdown_body.dart';

import 'export_assets_view_model.dart';

part 'export_assets_content.dart';

class ExportAssetsRoute extends BaseRoute {
  const ExportAssetsRoute();

  @override
  Widget buildPage(BuildContext context) => ExportAssetsView(params: this);
}

class ExportAssetsView extends StatelessWidget {
  const ExportAssetsView({
    super.key,
    required this.params,
  });

  final ExportAssetsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ExportAssetsViewModel>(
      create: (context) => ExportAssetsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ExportAssetsContent(viewModel);
      },
    );
  }
}
