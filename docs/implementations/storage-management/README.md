# Storage Management — Implementation Plan

A minimalist UI to see how much local and cloud storage the app is using, with simple cache-clearing actions.

---

## Goals

- Show local storage usage broken down by `SupportDirectoryPath` folder
- Show cloud storage quota (used / total) per signed-in `BackupCloudService`
- Cache fetched cloud quota in `PreferencesBox` so it's not re-fetched on every open
- Invalidate the cache when assets are added/removed/updated
- Allow clearing local caches (tmp, downloaded_from_firestore, export_assets)

---

## Architecture

```
lib/core/
  services/
    storage/
      storage_info_service.dart          # computes local dir sizes
  objects/
    cloud_storage_quota_object.dart      # data class: { used, limit } in bytes

lib/core/services/backups/
  backup_cloud_service.dart              # +fetchStorageQuota() abstract method
  google_drive_cloud_service.dart        # implements fetchStorageQuota()

lib/core/databases/adapters/objectbox/
  preferences_box.dart                   # +storageQuotaFor(serviceType)

lib/views/
  storage_management/
    storage_management_view.dart         # View + Route
    storage_management_view_model.dart   # ViewModel
    storage_management_content.dart      # Content (part of view)
```

---

## 1. Data class — `CloudStorageQuotaObject`

```dart
// lib/core/objects/cloud_storage_quota_object.dart

class CloudStorageQuotaObject {
  final int usageInBytes;
  final int? limitInBytes;   // null = unlimited / unknown

  const CloudStorageQuotaObject({
    required this.usageInBytes,
    this.limitInBytes,
  });

  factory CloudStorageQuotaObject.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }

  // convenience
  double? get fraction => limitInBytes != null ? usageInBytes / limitInBytes! : null;
}
```

---

## 2. `BackupCloudService` — new abstract method

Add one method to the existing abstract base class:

```dart
// lib/core/services/backups/backup_cloud_service.dart

/// Fetch cloud storage quota for the signed-in user.
/// Returns null if not signed in or unsupported.
Future<CloudStorageQuotaObject?> fetchStorageQuota();
```

Every `BackupCloudService` subclass must implement it.

---

## 3. `GoogleDriveCloudService` implementation

Uses the already-imported `googleapis/drive/v3.dart`:

```dart
@override
Future<CloudStorageQuotaObject?> fetchStorageQuota() async {
  final client = await googleDriveClient;
  if (client == null) return null;

  final about = await client.about.get($fields: 'storageQuota');
  final quota = about.storageQuota;
  if (quota == null) return null;

  return CloudStorageQuotaObject(
    usageInBytes: int.parse(quota.usage ?? '0'),
    limitInBytes: quota.limit != null ? int.parse(quota.limit!) : null,
  );
}
```

> No new packages needed. `googleapis` is already a dependency.

---

## 4. Caching in `PreferencesBox`

Add two `_DefinedPreference` entries — one for cached quota JSON, one for cache timestamp — per service:

```dart
// lib/core/databases/adapters/objectbox/preferences_box.dart

// IDs 100–109 reserved for storage quota cache
_DefinedPreference<String> storageQuotaFor(BackupServiceType serviceType) {
  return switch (serviceType) {
    BackupServiceType.google_drive => _DefinedPreference<String>(id: 100, key: 'storage_quota_google_drive'),
  };
}

_DefinedPreference<DateTime> storageQuotaFetchedAtFor(BackupServiceType serviceType) {
  return switch (serviceType) {
    BackupServiceType.google_drive => _DefinedPreference<DateTime>(id: 101, key: 'storage_quota_fetched_at_google_drive'),
  };
}
```

Cache strategy:

- On open: if cached value exists and is < 1 hour old → use cache; else → fetch + store
- On asset save/delete: call `PreferencesBox().storageQuotaFor(serviceType).set(null)` to invalidate
  - Hook into `AssetsBox` callbacks (the same `runCallbacks` mechanism already used)

---

## 5. `StorageInfoService` — local directory sizes

```dart
// lib/core/services/storage/storage_info_service.dart

class StorageInfoService {
  /// Returns size in bytes for each SupportDirectoryPath.
  Future<Map<SupportDirectoryPath, int>> computeLocalSizes() async { ... }

  /// Delete all files in a directory (does not remove the directory itself).
  Future<void> clearDirectory(SupportDirectoryPath path) async { ... }

  // Private helpers
  Future<int> _directorySize(Directory dir) async { ... }
}
```

---

## 6. `StorageManagementViewModel`

```dart
class StorageManagementViewModel extends ChangeNotifier {
  Map<SupportDirectoryPath, int>? localSizes;
  Map<BackupServiceType, CloudStorageQuotaObject?>? cloudQuotas;
  bool loading = true;

  Future<void> load(BuildContext context) async { ... }

  Future<void> clearCache(BuildContext context, SupportDirectoryPath path) async { ... }
}
```

- On `load()`:
  1. Compute local sizes via `StorageInfoService`
  2. For each signed-in `BackupCloudService`:
     - Check `PreferencesBox().storageQuotaFor(serviceType)` cache
     - If stale/absent → call `service.fetchStorageQuota()` → store result + timestamp
  3. `notifyListeners()`

---

## 7. `StorageManagementView` UI

Simple `ListView` with two sections:

```
── Local Storage ──────────────────────────────
  Images & Audio   [ 123 MB ]
  App Cache (tmp)  [   8 MB ]   [ Clear ]
  Backups          [   2 MB ]
  Exported Files   [   1 MB ]   [ Clear ]
  Firestore Cache  [   4 MB ]   [ Clear ]
  ─────────────────────────────────────────────
  Total            [ 138 MB ]

── Google Drive  (user@example.com) ──────────
  ████████░░░░░░  4.1 GB / 15 GB  (27%)
  ─────────────────────────────────────────────
  (hidden if not signed in)
```

- Sizes shown with a helper that formats bytes → B / KB / MB / GB
- "Clear" triggers `viewModel.clearCache(path)` + snackbar confirmation
- Tapping the Google Drive row opens the existing `ShowBackupServiceRoute`
- Loading state shows a `LinearProgressIndicator` in the AppBar

---

## 8. Entry point in Settings

```dart
// lib/views/settings/settings_content.dart  (General section, after Backup Services tile)

ListTile(
  leading: SpSettingIconBadge(icon: SpIcons.storage, weekday: 6),
  title: Text(tr('page.storage_management.title')),
  onTap: () => const StorageManagementRoute().push(context),
),
```

---

## Cache Invalidation Hook

In `AssetsBox` (or base box callbacks), after any `set` / `delete`:

```dart
for (final serviceType in BackupServiceType.values) {
  PreferencesBox().storageQuotaFor(serviceType).set('');  // empty = stale
}
```

This ensures the next time the storage page is opened, quotas are re-fetched.

---

## File Summary

| File                                                              | Action                             |
| ----------------------------------------------------------------- | ---------------------------------- |
| `lib/core/objects/cloud_storage_quota_object.dart`                | **New**                            |
| `lib/core/services/backups/backup_cloud_service.dart`             | Add `fetchStorageQuota()` abstract |
| `lib/core/services/backups/google_drive_cloud_service.dart`       | Implement `fetchStorageQuota()`    |
| `lib/core/services/storage/storage_info_service.dart`             | **New**                            |
| `lib/core/databases/adapters/objectbox/preferences_box.dart`      | Add cache entries                  |
| `lib/views/storage_management/storage_management_view.dart`       | **New**                            |
| `lib/views/storage_management/storage_management_view_model.dart` | **New**                            |
| `lib/views/storage_management/storage_management_content.dart`    | **New**                            |
| `lib/views/settings/settings_content.dart`                        | Add tile                           |
