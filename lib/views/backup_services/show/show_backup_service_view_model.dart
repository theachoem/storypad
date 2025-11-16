import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'show_backup_service_view.dart';

class ShowBackupServiceViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowBackupServiceRoute params;

  ShowBackupServiceViewModel({
    required this.params,
  });
}
