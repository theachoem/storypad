import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/adapters/objectbox/preferences_box.dart';
import 'package:storypad/core/objects/cloud_storage_quota_object.dart';
import 'package:storypad/core/services/backups/backup_service_type.dart';
import 'package:storypad/core/services/storage/storage_info_service.dart';
import 'package:storypad/core/types/support_directory_path.dart';
import 'package:storypad/providers/backup_provider.dart';

import 'storage_management_view.dart';

class StorageManagementViewModel extends ChangeNotifier {
  final StorageManagementRoute params;

  StorageManagementViewModel({
    required this.params,
    required BuildContext context,
  }) {
    load(context);
  }

  static const Duration _cacheTtl = Duration(hours: 1);
  static const Duration _reloadCooldown = Duration(minutes: 1);

  /// Directories grouped as cache files in the UI.
  static const List<SupportDirectoryPath> cacheDirectories = [
    SupportDirectoryPath.tmp,
    SupportDirectoryPath.export_assets,
    SupportDirectoryPath.downloaded_from_firestore,
  ];

  Map<SupportDirectoryPath, int> localSizes = {};
  Map<BackupServiceType, CloudStorageQuotaObject?> cloudQuotas = {};
  int cachedNetworkImageBytes = 0;

  bool loading = true;
  bool reloading = false;
  DateTime? _lastReloadAt;

  Future<void> load(BuildContext context) async {
    loading = true;
    notifyListeners();

    await Future.wait([
      _loadLocalSizes(),
      _loadCloudQuotas(context),
    ]);

    loading = false;
    notifyListeners();
  }

  Future<void> _loadLocalSizes() async {
    final storageInfoService = StorageInfoService();
    final results = await Future.wait([
      storageInfoService.computeLocalSizes(),
      storageInfoService.computeCachedNetworkImageCacheSize(),
    ]);

    localSizes = results[0] as Map<SupportDirectoryPath, int>;
    cachedNetworkImageBytes = results[1] as int;
  }

  Future<void> _loadCloudQuotas(BuildContext context) async {
    final services = context.read<BackupProvider>().repository.services;

    for (final service in services) {
      if (!service.isSignedIn) continue;

      final serviceType = service.serviceType;
      final cached = _readCachedQuota(serviceType);

      if (cached != null) {
        cloudQuotas[serviceType] = cached;
        continue;
      }

      final quota = await service.fetchStorageQuota();
      cloudQuotas[serviceType] = quota;

      if (quota != null) {
        PreferencesBox().storageQuotaFor(serviceType).set(quota.toJsonString());
        PreferencesBox().storageQuotaFetchedAtFor(serviceType).set(DateTime.now());
      }
    }
  }

  CloudStorageQuotaObject? _readCachedQuota(BackupServiceType serviceType) {
    final fetchedAt = PreferencesBox().storageQuotaFetchedAtFor(serviceType).get();
    if (fetchedAt == null) return null;
    if (DateTime.now().difference(fetchedAt) > _cacheTtl) return null;

    final json = PreferencesBox().storageQuotaFor(serviceType).get();
    return CloudStorageQuotaObject.tryParseJsonString(json);
  }

  Future<void> clearCacheFiles(BuildContext context) async {
    final storageInfoService = StorageInfoService();

    for (final path in cacheDirectories) {
      await storageInfoService.clearDirectory(path);
    }

    await storageInfoService.clearCachedNetworkImageCache();

    await _loadLocalSizes();
    notifyListeners();
  }

  bool get canReload {
    if (_lastReloadAt == null) return true;
    return DateTime.now().difference(_lastReloadAt!) >= _reloadCooldown;
  }

  Duration? get reloadCooldownRemaining {
    if (_lastReloadAt == null) return null;
    final remaining = _reloadCooldown - DateTime.now().difference(_lastReloadAt!);
    return remaining.isNegative ? null : remaining;
  }

  Future<void> reload(BuildContext context) async {
    if (!canReload) return;

    reloading = true;
    notifyListeners();
    _lastReloadAt = DateTime.now();

    // Clear cache to force fresh fetch
    for (final serviceType in BackupServiceType.values) {
      PreferencesBox().storageQuotaFor(serviceType).set('');
    }

    try {
      await Future.wait([
        _loadLocalSizes(),
        _loadCloudQuotas(context),
      ]);
    } finally {
      reloading = false;
      notifyListeners();
    }
  }

  int get cacheFilesBytes => cacheDirectories.fold(0, (a, p) => a + (localSizes[p] ?? 0)) + cachedNetworkImageBytes;

  int get totalLocalBytes => localSizes.values.fold(0, (a, b) => a + b) + cachedNetworkImageBytes;
}
