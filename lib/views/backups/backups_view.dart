import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/base/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/objects/backup_file_object.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/services/date_format_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/routes/base_route.dart';
import 'package:storypad/views/backups/local_widgets/user_profile_collapsible_tile.dart';
import 'package:storypad/widgets/sp_default_scroll_controller.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

import 'backups_view_model.dart';

part 'backups_adaptive.dart';

class BackupsRoute extends BaseRoute {
  BackupsRoute();

  @override
  Widget buildPage(BuildContext context) => BackupsView(params: this);

  @override
  bool get nestedRoute => true;
}

class BackupsView extends StatelessWidget {
  const BackupsView({
    super.key,
    required this.params,
  });

  final BackupsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<BackupsViewModel>(
      create: (context) => BackupsViewModel(context: context, params: params),
      builder: (context, viewModel, child) {
        return _BackupsAdaptive(viewModel);
      },
    );
  }
}
