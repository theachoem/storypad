import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:storypad/core/objects/backup_object.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:storypad/widgets/base_view/base_route.dart';

import 'show_backup_view_model.dart';

part 'show_backup_content.dart';

class ShowBackupsRoute extends BaseRoute {
  ShowBackupsRoute(this.backup);

  final BackupObject backup;

  @override
  Widget buildPage(BuildContext context) => ShowBackupView(params: this);
}

class ShowBackupView extends StatelessWidget {
  const ShowBackupView({
    super.key,
    required this.params,
  });

  final ShowBackupsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowBackupsViewModel>(
      create: (context) => ShowBackupsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowBackupContent(viewModel);
      },
    );
  }
}
