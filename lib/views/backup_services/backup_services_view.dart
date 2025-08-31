import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/views/backup_services/show/show_backup_service_view.dart';
import 'package:storypad/views/import_export/import_export_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';

import 'backup_services_view_model.dart';

part 'backup_services_content.dart';

class BackupServicesRoute extends BaseRoute {
  const BackupServicesRoute();

  @override
  Widget buildPage(BuildContext context) => BackupServicesView(params: this);
}

class BackupServicesView extends StatelessWidget {
  const BackupServicesView({
    super.key,
    required this.params,
  });

  final BackupServicesRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<BackupServicesViewModel>(
      create: (context) => BackupServicesViewModel(params: params),
      builder: (context, viewModel, child) {
        return _BackupServicesContent(viewModel);
      },
    );
  }
}
