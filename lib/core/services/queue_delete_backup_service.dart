import 'dart:async';

import 'package:flutter/material.dart';
import 'package:storypad/core/services/backup_sources/base_backup_source.dart';

class QueueDeleteBackupService {
  final BaseBackupSource source;

  final Set<String> _toDeleteBackupIds = {};
  Timer? _deletingBackupTimer;
  String? _deletingBackupId;

  QueueDeleteBackupService({
    required this.source,
  });

  void delete(String cloudId) {
    _toDeleteBackupIds.add(cloudId);
    _deletingBackupTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      String? toDeleteId = _toDeleteBackupIds.firstOrNull;
      debugPrint('BackupProvider#deleteHistoryQueue queue timer: $_deletingBackupId');

      if (toDeleteId == null) {
        _deletingBackupTimer?.cancel();
        _deletingBackupTimer = null;
        return;
      }

      if (_deletingBackupId != null) return;
      _deletingBackupId = toDeleteId;
      await source.deleteCloudFile(toDeleteId);

      _deletingBackupId = null;
      if (_toDeleteBackupIds.contains(toDeleteId)) _toDeleteBackupIds.remove(toDeleteId);
    });
  }
}
