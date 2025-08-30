import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'delete_backup_provider_view_model.dart';

part 'delete_backup_provider_content.dart';

class DeleteBackupProviderRoute extends BaseRoute {
  const DeleteBackupProviderRoute();

  @override
  Widget buildPage(BuildContext context) => DeleteBackupProviderView(params: this);
}

class DeleteBackupProviderView extends StatelessWidget {
  const DeleteBackupProviderView({
    super.key,
    required this.params,
  });

  final DeleteBackupProviderRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<DeleteBackupProviderViewModel>(
      create: (context) => DeleteBackupProviderViewModel(params: params),
      builder: (context, viewModel, child) {
        return _DeleteBackupProviderContent(viewModel);
      },
    );
  }
}
