import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';

import 'import_export_view_model.dart';

part 'import_export_content.dart';

class ImportExportRoute extends BaseRoute {
  const ImportExportRoute();

  @override
  Widget buildPage(BuildContext context) => ImportExportView(params: this);
}

class ImportExportView extends StatelessWidget {
  const ImportExportView({
    super.key,
    required this.params,
  });

  final ImportExportRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ImportExportViewModel>(
      create: (context) => ImportExportViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ImportExportContent(viewModel);
      },
    );
  }
}
