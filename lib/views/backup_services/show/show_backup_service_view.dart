import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/views/backup_services/delete/delete_backup_provider_view.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';

import 'show_backup_service_view_model.dart';

part 'show_backup_service_content.dart';

class ShowBackupServiceRoute extends BaseRoute {
  final BackupCloudService service;

  const ShowBackupServiceRoute({
    required this.service,
  });

  @override
  Widget buildPage(BuildContext context) => ShowBackupServiceView(params: this);
}

class ShowBackupServiceView extends StatelessWidget {
  const ShowBackupServiceView({
    super.key,
    required this.params,
  });

  final ShowBackupServiceRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowBackupServiceViewModel>(
      create: (context) => ShowBackupServiceViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowBackupServiceContent(viewModel);
      },
    );
  }
}
