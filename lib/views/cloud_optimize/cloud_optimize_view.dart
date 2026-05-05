import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/color_from_day_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'cloud_optimize_view_model.dart';

part 'cloud_optimize_content.dart';

class CloudOptimizeRoute extends BaseRoute {
  final BackupCloudService service;
  final String userIdentifier;

  const CloudOptimizeRoute({
    required this.service,
    required this.userIdentifier,
  });

  @override
  String? get routeName => null;

  @override
  Widget buildPage(BuildContext context) => CloudOptimizeView(params: this);
}

class CloudOptimizeView extends StatelessWidget {
  const CloudOptimizeView({
    super.key,
    required this.params,
  });

  final CloudOptimizeRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CloudOptimizeViewModel>(
      create: (context) => CloudOptimizeViewModel(
        params: params,
        service: params.service,
        userIdentifier: params.userIdentifier,
        syncCallback: () async {
          if (!context.mounted) return false;

          final backupProvider = context.read<BackupProvider>();
          return backupProvider.recheckAndSync(
            services: backupProvider.services.where((service) => service.isSignedIn).toList(),
          );
        },
      ),
      builder: (context, _) {
        return _CloudOptimizeContent(Provider.of(context));
      },
    );
  }
}
