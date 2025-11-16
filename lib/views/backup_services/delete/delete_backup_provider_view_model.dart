import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'delete_backup_provider_view.dart';

class DeleteBackupProviderViewModel extends ChangeNotifier with DisposeAwareMixin {
  final DeleteBackupProviderRoute params;

  DeleteBackupProviderViewModel({
    required this.params,
  });
}
