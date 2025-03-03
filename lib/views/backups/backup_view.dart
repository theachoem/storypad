import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/objects/cloud_file_object.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/view/base_route.dart';
import 'package:storypad/views/backups/local_widgets/user_profile_collapsible_tile.dart';
import 'package:storypad/views/backups/offline_backup/offline_backup_view.dart';
import 'package:storypad/widgets/sp_default_scroll_controller.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

import 'backup_view_model.dart';

part 'backup_content.dart';
part 'local_widgets/backup_tile_monogram.dart';
part 'local_widgets/timeline_divider.dart';

class BackupRoute extends BaseRoute {
  BackupRoute();

  @override
  Widget buildPage(BuildContext context) => BackupView(params: this);

  @override
  bool get preferredNestedRoute => true;
}

class BackupView extends StatelessWidget {
  const BackupView({
    super.key,
    required this.params,
  });

  final BackupRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<BackupViewModel>(
      create: (context) => BackupViewModel(context: context, params: params),
      builder: (context, viewModel, child) {
        return _BackupContent(viewModel);
      },
    );
  }
}
