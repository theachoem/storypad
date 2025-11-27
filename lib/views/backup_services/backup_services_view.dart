import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/views/backup_services/local_widgets/backup_service_tile.dart';
import 'package:storypad/views/import_export/import_export_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

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
      create: (context) => BackupServicesViewModel(context: context, params: params),
      builder: (context, viewModel, child) {
        return _BackupServicesContent(viewModel);
      },
    );
  }
}
