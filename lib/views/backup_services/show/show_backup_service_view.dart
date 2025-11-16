import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
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
      create: (context) => ShowBackupServiceViewModel(params: params, context: context),
      builder: (context, viewModel, child) {
        return _ShowBackupServiceContent(viewModel);
      },
    );
  }
}
