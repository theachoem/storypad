import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/providers/backup_provider.dart';
import 'backup_services_view.dart';

class BackupServicesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final BackupServicesRoute params;

  BackupServicesViewModel({
    required this.params,
    required BuildContext context,
  }) {
    services = context.read<BackupProvider>().services;
  }

  late final List<BackupCloudService> services;
}
