import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'offline_backup_view_model.dart';

part 'offline_backup_content.dart';

class OfflineBackupRoute extends BaseRoute {
  OfflineBackupRoute();

  @override
  bool get preferredNestedRoute => true;

  @override
  Widget buildPage(BuildContext context) => OfflineBackupView(params: this);
}

class OfflineBackupView extends StatelessWidget {
  const OfflineBackupView({
    super.key,
    required this.params,
  });

  final OfflineBackupRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<OfflineBackupViewModel>(
      create: (context) => OfflineBackupViewModel(params: params),
      builder: (context, viewModel, child) {
        return _OfflineBackupsContent(viewModel);
      },
    );
  }
}
