import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:storypad/core/databases/models/asset_db_model.dart';
import 'package:storypad/core/services/backups/backup_cloud_service.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/core/services/retry/retry_executor.dart';
import 'package:storypad/core/services/retry/retry_policy.dart';

/// Assets that a service's legacy (v3) backups list as in use.
///
/// An app from before Markdown pages writes only legacy backups, which this app doesn't import for a year that has a
/// current file -- so the photos and voice notes it adds have no record here, and Cloud Optimize would take their
/// files for detached ones.
///
/// TODO: remove once no device runs an app before 2.34.0 (v3 backups) -- see `OlderAppLastSeenStorage`.
class OlderAppAssetIdsService {
  const OlderAppAssetIdsService._();

  /// Null when a legacy backup couldn't be read: what it lists is unknown.
  static Future<Set<int>?> fetch(BackupCloudService service) async {
    try {
      final files = await RetryExecutor.execute(
        () => service.fetchYearlyBackups(),
        policy: RetryPolicy.network,
        operationName: 'older_app_asset_ids_fetch_${service.serviceType.id}',
      );

      final table = AssetDbModel.db.tableName;
      final ids = <int>{};
      for (final file in files.legacy.values) {
        final contents = await RetryExecutor.execute(
          () => service.getFileContent(file),
          policy: RetryPolicy.network,
          operationName: 'older_app_asset_ids_download_${service.serviceType.id}',
        );
        if (contents == null) return null;

        ids.addAll(await compute(_liveAssetIdsIn, (contents.$1, table)));
      }
      return ids;
    } catch (e) {
      AppLogger.d('OlderAppAssetIdsService#fetch failed: $e');
      return null;
    }
  }

  /// Ids of the assets a backup's contents list in [table], leaving out deleted ones.
  @visibleForTesting
  static Set<int> liveAssetIdsIn(String contents, String table) {
    final json = jsonDecode(contents) as Map<String, dynamic>;
    // Where `BackupObject.fromContents` reads the tables from.
    final tables = (json['data'] ?? json['tables']) as Map<String, dynamic>;
    final assets = tables[table] as List<dynamic>? ?? const [];
    return {
      for (final asset in assets.whereType<Map<String, dynamic>>())
        if (asset['permanently_deleted_at'] == null)
          if (asset['id'] case final num id) id.toInt(),
    };
  }
}

Set<int> _liveAssetIdsIn((String, String) message) => OlderAppAssetIdsService.liveAssetIdsIn(message.$1, message.$2);
