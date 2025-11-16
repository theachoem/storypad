import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'show_backup_service_view.dart';

class ShowBackupServiceViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowBackupServiceRoute params;

  late final BackupServiceType metadata;

  ShowBackupServiceViewModel({
    required this.params,
  }) {
    metadata = params.service.serviceType;
  }
}
