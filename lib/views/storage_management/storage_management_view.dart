import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/types/support_directory_path.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';
import 'package:storypad/views/cloud_optimize/cloud_optimize_view.dart';

import 'storage_management_view_model.dart';

part 'storage_management_content.dart';

class StorageManagementRoute extends BaseRoute {
  const StorageManagementRoute();

  @override
  String? get routeName => 'storage_management';

  @override
  Widget buildPage(BuildContext context) => StorageManagementView(params: this);
}

class StorageManagementView extends StatelessWidget {
  const StorageManagementView({
    super.key,
    required this.params,
  });

  final StorageManagementRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StorageManagementViewModel>(
      create: (context) => StorageManagementViewModel(params: params, context: context),
      builder: (context, child) {
        return _StorageManagementContent(Provider.of(context));
      },
    );
  }
}
