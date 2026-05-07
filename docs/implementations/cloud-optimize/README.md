# Cloud Storage Optimize

Optimize scans cloud asset folders, identifies files that are no longer needed, and frees cloud quota without risking user memories.

The guiding rule is conservative: **do not permanently delete asset files from Optimize**. For Google Drive, cleanup moves files to Drive trash first. Google automatically removes trashed files later, and in-app restore should be a separate explicit user action, not an automatic side effect of downloading an asset.

## What Files Are Scanned

Assets are uploaded into provider app-scoped folders:

| Folder   | Contains                | Example filename    |
| -------- | ----------------------- | ------------------- |
| `images` | image assets            | `1762500783746.jpg` |
| `audio`  | audio/voice note assets | `1762500783747.m4a` |

Backup files in `backups/` are never optimized by this flow.

## Safety Model

### Why Detached Is Risky

A detached file is a cloud file whose filename stem parses to an asset ID, but this device has no active `AssetDbModel` for that ID.

That does **not** automatically mean the file is garbage. It can happen when another device uploaded the memory and this device has not imported the latest backup yet. Deleting immediately would risk deleting a real photo or audio memory.

### Safe Path

Detached cleanup can be allowed, but only after all of these gates pass:

1. **Sync preflight succeeds** for every signed-in backup provider.
   - Use `BackupProvider.recheckAndSync(services: signedInServices)` or a repository-level equivalent.
   - If sync fails or is skipped because the app is offline, detached cleanup must be disabled for this run.
   - This imports remote `AssetDbModel` records before we trust local absence.
2. **Fresh scan after sync** lists `images` and `audio` again.
3. **Fresh DB lookup after scan** confirms no active asset record references the parsed ID.
4. **Age gate passes**.
   - Default: cloud file is at least 30 days old.
   - Use provider metadata `createdTime`; also validate the parsed filename timestamp when it looks like milliseconds-since-epoch.
5. **Final re-verification immediately before trashing** fetches a fresh cloud file list and re-runs the analyzer and DB lookup.
6. **Move to trash, not permanent delete**.

This is not mathematically perfect, but it covers the common real-world case safely: a user opens Optimize on a synced device, and old cloud files with no corresponding asset record are almost certainly leftovers.

## File Classification

### Clean

Leave the file alone.

- Filename cannot be parsed as an asset ID.
- Active `AssetDbModel` exists and any stored destination points to this cloud file ID.
- Active `AssetDbModel` exists but no live copy can be confirmed for the stored destination.

### Stale Duplicate

A cloud file is stale when:

- Active `AssetDbModel` exists for the parsed asset ID.
- No stored destination points to this cloud file ID.
- A different stored destination file ID is present in the fetched cloud set.

This is safe to clean because the active copy is confirmed. Stale duplicates may be moved to trash immediately after final re-verification.

### Detached Candidate

A cloud file is a detached candidate when:

- Filename parses to an asset ID.
- Sync preflight completed successfully.
- No active `AssetDbModel` exists for the parsed ID after sync.
- File is older than the detached grace period.

If `AssetDbModel.db.find(id, returnDeleted: true)` returns a deleted/tombstone asset whose `permanentlyDeletedAt` is also older than the grace period, that is stronger evidence than no record at all. The memory deletion has synced locally, so the cloud asset can be moved to trash after the same final re-verification.

If there is no active record and no tombstone, the file can still be moved to trash only after sync + age gate. This covers orphan leftovers, but it should be presented as recoverable cleanup.

## Google Drive Trash Strategy

Use Drive trash as the safety net:

- Replace Optimize's permanent `deleteFile` path with `trashFile` for asset cleanup.
- Implement `restoreFileFromTrash(fileId)` for recovery.
- Keep `deleteFile` only for explicit permanent-delete use cases outside Optimize.
- Continue normal scans with `trashed=false` so trashed files disappear from Optimize results.
- Add a provider method that can fetch a file by ID including trashed metadata.

Suggested Google Drive API shape:

```dart
Future<bool> trashFile(String fileId) async {
  await client.files.update(
    drive.File()..trashed = true,
    fileId,
    $fields: 'id,name,trashed,createdTime,modifiedTime,size',
  );
  return true;
}

Future<bool> restoreFileFromTrash(String fileId) async {
  await client.files.update(
    drive.File()..trashed = false,
    fileId,
    $fields: 'id,name,trashed,createdTime,modifiedTime,size',
  );
  return true;
}
```

Google Drive normally auto-removes trashed files after about 30 days. After that window, the app cannot recover the file from trash.

## Restore Strategy

Optimize does not restore files automatically during asset download. If a download returns 404, `GoogleDriveAssetDownloaderService` logs a Crashlytics breadcrumb and shows the normal download error.

Manual restoration should be added as a separate recovery surface later, such as a page that lists trashed app files and lets the user choose which files to restore. `restoreFileFromTrash(fileId)` and `findFileByIdIncludingTrashed(fileId)` exist for that future explicit flow.

## UI Steps

| Step | Title             | Purpose                                                                      |
| ---- | ----------------- | ---------------------------------------------------------------------------- |
| 1    | Sync latest data  | Run backup sync for signed-in providers before trusting local DB absence.    |
| 2    | Fetch cloud files | List `images` and `audio` with `trashed=false`.                              |
| 3    | Analyze files     | Classify clean, stale duplicate, and detached candidate files.               |
| 4    | Clean up          | Move eligible stale and detached files to trash after final re-verification. |

If sync fails, continue showing stale duplicate cleanup only if we still have enough proof, but disable detached cleanup and explain that sync is required before detached files can be cleaned.

## Implementation Notes

1. `CloudFileObject`.
   - Add `createdAt`, `modifiedAt`, and `trashed` fields from Google Drive metadata.
   - Update Drive `$fields` for list/get calls.
2. `BackupCloudService`.
   - Add `trashFile(fileId)`.
   - Add `restoreFileFromTrash(fileId)`.
   - Add `findFileById(fileId, includeTrashed: true)` or a separate `findFileByIdIncludingTrashed` method.
3. Google Drive service.
   - Implement trash/untrash with `files.update`.
   - Keep `listFilesInFolder` defaulting to `trashed=false`.
   - Make file-not-found during trash idempotent: already gone means cleanup succeeded.
4. Analyzer input.
   - Keep pure classification for clean/stale/detached.
   - Add a separate pure eligibility helper for detached cleanup age gates.
   - Query records with `returnDeleted: true` where needed to distinguish active missing vs deleted tombstone.
5. Optimize ViewModel.
   - Add `syncing` step before fetch.
   - Inject or access backup sync orchestration so Optimize can run sync preflight.
   - Only allow detached cleanup when sync preflight succeeds.
   - Move stale + eligible detached files to trash, not permanent delete.
6. Downloader observability.
   - On 404 download failure for a Google Drive-backed asset, log a Crashlytics breadcrumb.
   - Do not automatically restore or retry trashed files from the downloader.
7. UI copy.
   - Use “Move to trash” language, not “Delete permanently.”
   - Show detached candidates separately with the 30-day safety rule.
   - Avoid promising automatic recovery until the manual bin/restore page exists.

## Tests

Analyzer and eligibility tests should cover:

- Detached file younger than 30 days is not eligible.
- Detached file older than 30 days is eligible only when sync preflight succeeded.
- Detached file with active record after sync is clean.
- Detached file with deleted tombstone older than 30 days is eligible.
- Detached file with deleted tombstone younger than 30 days is not eligible.
- Stale duplicate remains eligible without detached rules when live copy exists.
- Final re-verification removes a candidate if a record appears after analysis.
- Download 404 path logs a Crashlytics breadcrumb and does not restore automatically.

## Defaults

| Setting                        | Default       |
| ------------------------------ | ------------- |
| Detached grace period          | 30 days       |
| Cleanup operation              | Move to trash |
| Permanent delete from Optimize | Never         |
| Restore attempt on download    | None          |

## Decision

Yes, detached files can be cleaned, but the safe product behavior is **sync first + old enough + move to trash**. Age alone is not safe. Sync alone is not safe. Permanent delete is unnecessary risk. Together, these gates give users useful cleanup without making one device's temporarily incomplete local database the source of truth for deleting memories.
