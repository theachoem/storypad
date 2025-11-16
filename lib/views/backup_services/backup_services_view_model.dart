import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'backup_services_view.dart';

class BackupServicesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final BackupServicesRoute params;

  BackupServicesViewModel({
    required this.params,
  });
}
