# Backup System

Comprehensive backup/sync implementation with Google Drive, featuring robust exception handling, retry logic, and multi-device synchronization.

## Overview

The backup system provides automatic cloud backup and sync for StoryPad data across multiple devices using Google Drive. It handles database backups, image/audio assets, and ensures data consistency across devices through intelligent conflict resolution.

### Key Capabilities

- **Automatic Sync**: Background synchronization on app start and data changes
- **Multi-Device Support**: Conflict resolution based on timestamps across devices
- **Yearly Partitioning**: Separate backup files per year for faster sync (v3 format)
- **Asset Backup**: Images and audio files uploaded separately to Google Drive
- **Compression**: GZIP compression for backup files
- **Offline Support**: Works offline, syncs when connection restored
- **Error Recovery**: Automatic retry with exponential backoff
- **Type-Safe**: No exceptions thrown to UI, uses `BackupResult<T>` pattern

### 4-Step Sync Process

```
Step 1: Upload Images/Audio → Step 2: Check Latest Backup
         ↓                              ↓
Step 4: Upload New Backup   ← Step 3: Import Remote Changes
```

**Step 1 - Upload Assets**: Upload any local images/audio that haven't been backed up
**Step 2 - Check Latest**: Fetch the latest backup file from Google Drive
**Step 3 - Import Changes**: Apply remote changes that are newer than local data
**Step 4 - Upload Backup**: Create and upload new backup with local changes

## Architecture

**Exception Flow:**

```
Google Drive Client → Service → Repository → Provider
     (Throws)      → (Wraps) → (Result)  → (UI State)
```

**Data Flow:**

```
Local DB Changes → BackupProvider → BackupRepository → [4 Steps] → Google Drive
                        ↓                                               ↓
                   UI Updates  ← StreamControllers ← Progress Messages
```

## Components

### Core Files & Responsibilities

**`BackupRepository`** (`lib/core/repositories/backup_repository.dart`)

- Central coordinator for all backup operations
- Manages 4-step sync process
- Returns `BackupResult<T>` (never throws to caller)
- Auto sign-out on auth failures
- Tracks databases: Stories, Tags, Events, Templates, Assets, Preferences, RelaxSoundMix

**`BackupProvider`** (`lib/providers/backup_provider.dart`)

- State management for backup UI
- Listens to all 4 step streams for progress updates
- Manages `connectionStatus`, `lastSyncedAt`, `lastDbUpdatedAt`
- Triggers sync on app start and database changes
- Handles user sign-in/sign-out flows

**`GoogleDriveClient`** (`lib/core/services/google_drive_client.dart`)

- Low-level Google Drive API wrapper
- Token management (refresh, expiration detection)
- HTTP status code → exception mapping
- Auto reauthentication on token expiry
- File operations: upload, download, list, delete

### Exception Types (`lib/core/exceptions/backup_exceptions.dart`)

**Base:** `BackupException` - message, context, retry info

**Types:**

- `NetworkException` - Network issues (retryable)
- `AuthException` - Auth failures (tokenExpired, tokenRevoked, insufficientScopes, signInRequired, signInFailed)
- `QuotaException` - Drive quota/rate limits
- `FileOperationException` - File ops (retryable)
- `ServiceException` - Business logic errors
- `ConfigurationException` - Setup errors

### Result Types (`lib/core/types/backup_result.dart`)

**BackupResult<T>** (sealed):

- `BackupSuccess<T>` - Success
- `BackupFailure<T>` - Complete failure
- `BackupPartialSuccess<T>` - Mixed results

**BackupError:** Type classification, user messages, retry flags, metadata

### Retry Policy (`lib/core/utils/retry_policy.dart`)

- Configurable attempts, delays, exponential backoff
- Predefined: `RetryPolicy.network`, `RetryPolicy.quota`, `RetryPolicy.none`
- `RetryExecutor` - Auto retry with timeout

### Google Drive Client (`lib/core/services/google_drive_client.dart`)

- Token expiration/revocation detection
- HTTP status → exception mapping
- Auto retry for transient failures

### Services

**`BackupImagesUploaderService`** (Step 1)

- Uploads images/audio assets marked with `needBackup = true`
- Updates `cloudDestinations` map on asset model
- Uses retry policy for failed uploads
- Emits progress via `BackupSyncMessage` stream

**`BackupLatestCheckerService`** (Step 2)

- Fetches yearly backup files from Google Drive `backups/` folder
- Downloads and decompresses backup content for years that need syncing (GZIP)
- Validates backup structure
- Returns `BackupLatestCheckerResponse` with yearly file info and content

**`BackupImporterService`** (Step 3)

- Compares remote yearly backups with local database
- Only applies records with newer `updatedAt` timestamps
- Uses `RestoreBackupService` for actual data insertion
- Prevents overwriting newer local changes

**`BackupUploaderService`** (Step 4)

- Converts local databases to `BackupObject` per year
- Compresses data with GZIP (v3 yearly format)
- Uploads to Google Drive `backups/` folder with year-based filename
- Uses atomic update for existing files, creates new files for new years
- Returns uploaded file metadata

**`RestoreBackupService`** (`utils/`)

- Handles data insertion without overwriting newer records
- `restoreOnlyNewData()`: Selective restore based on timestamps
- `forceRestore()`: Complete restore (used in backup viewer)
- Triggers callbacks after restore for UI updates

**`BackupDatabasesToBackupObjectService`** (`utils/`)

- Serializes database tables to JSON (optionally filtered by year)
- Creates `BackupObject` with metadata (device info, timestamps, year)
- Supports v3 yearly backups (when year provided) and legacy v2 format (for manual export)
- Excludes sensitive data from backup

**`JsonTablesToModelService`** (`utils/`)

- Deserializes backup JSON to database models
- Validates data structure
- Maps table names to model classes

### Repository (`lib/core/repositories/backup_repository.dart`)

- Returns `BackupResult<T>` (no throws)
- Auto sign-out on auth errors
- Connection status mapping

**Key Methods:**

- `signIn()` / `signOut()` / `requestScope()`: Authentication management
- `startStep1()` to `startStep4()`: Execute sync steps
- `checkConnection()`: Verify internet and auth status
- `getLastDbUpdatedAtByYear()`: Track local changes timestamp per year (v3)

### Provider (`lib/providers/backup_provider.dart`)

- Handles `BackupResult` types
- User-friendly error messages
- Auto sign-out on token revocation

**State Properties:**

- `connectionStatus`: Current connection state (enum)
- `lastSyncedAtByYear`: Map of year → last sync timestamp (v3)
- `lastDbUpdatedAtByYear`: Map of year → last DB update timestamp (v3)
- `lastSyncedAt`: Latest timestamp across all years (computed)
- `lastDbUpdatedAt`: Latest timestamp across all years (computed)
- `synced`: Boolean indicating if local == remote (all years)
- `step1Message` to `step4Message`: Progress for each step

**Key Methods:**

- `recheckAndSync()`: Main entry point for sync process
- `signIn()` / `signOut()` / `requestScope()`: User actions
- `_syncBackupAcrossDevices()`: Internal 4-step orchestration

## Multi-Device Sync Logic

The system ensures data consistency across devices through timestamp-based conflict resolution:

### Sync Scenario Example

**Device A (12:00 PM)**

1. User writes Story #1
2. Syncs to Google Drive (backup contains Story #1)

**Device B (3:00 PM)**

1. User writes Story #2
2. Before syncing, retrieves backup from 12:00 PM
3. Compares: Story #1 from backup (12:00 PM) vs local (doesn't exist)
4. Imports Story #1 (newer than non-existent)
5. Uploads new backup (contains both Story #1 and #2)

**Device A (6:00 PM)**

1. Opens app, triggers sync
2. Retrieves backup from 3:00 PM
3. Compares: Story #2 from backup (3:00 PM) vs local (doesn't exist)
4. Imports Story #2
5. Now has both stories

### Conflict Resolution Rules

- **Timestamp Comparison**: `record.updatedAt` determines winner
- **Newer Wins**: Remote record replaces local if `remote.updatedAt > local.updatedAt`
- **Insert Only**: New records (not in local DB) are always inserted
- **No Deletion Sync**: Deletions on one device don't propagate (by design)
- **Per-Record Granularity**: Each record compared individually

## Backup File Format

### Version 3 (Yearly Partitioning)

The current backup system uses yearly partitioning for better performance and scalability.

**Google Drive Structure:**

```
appDataFolder/
  ├── images/                    ← Image assets
  ├── audio/                     ← Audio assets
  └── backups/                   ← v3 yearly backups folder
      ├── Backup::3::2025::1734350000000::iPhone 15 Pro::ABC123.zip
      ├── Backup::3::2024::1704067200000::iPad Pro::DEF456.zip
      └── Backup::3::2023::1672531200000::iPhone 15 Pro::ABC123.zip
```

**Filename Format**: `Backup::3::{year}::{timestamp}::{device_model}::{device_id}.zip`

**Example**: `Backup::3::2025::1734350000000::iPhone 15 Pro::ABC123.zip`

```json
{
  "version": 1,
  "year": 2025,
  "meta_data": {
    "created_at": "2025-11-15T10:30:00.000Z",
    "device_model": "iPhone 15 Pro",
    "device_id": "ABC123DEF456"
  },
  "tables": {
    "stories": [
      {
        "id": "...",
        "title": "...",
        "createdAt": "2025-...",
        "updatedAt": "..."
      }
    ],
    "tags": [
      /* only records created in 2025 */
    ],
    "events": [
      /* only records created in 2025 */
    ],
    "templates": [
      /* only records created in 2025 */
    ],
    "assets": [
      /* only records created in 2025 */
    ],
    "preferences": [
      /* only records created in 2025 */
    ],
    "relax_sound_mixes": [
      /* only records created in 2025 */
    ]
  }
}
```

**Key Changes**:

- **Per-Year Files**: Separate backup file for each year (2025, 2024, 2023, etc.)
- **Smart Sync**: Only upload/download years with changes since last sync
- **Smaller Files**: Each file contains only one year's data (~2-3 MB vs 15+ MB)
- **Year in Filename**: Year is explicitly part of the filename for easy identification

**Benefits**:

- ⚡ **3-5x Faster**: Sync only changed years instead of entire history
- 💾 **Smaller Files**: Individual yearly files much smaller than monolithic backup
- 🔄 **Better Scalability**: Performance doesn't degrade with years of usage
- 📊 **Easier Management**: View/restore specific years independently

### Legacy Format (v1/v2)

```json
{
  "version": 1,
  "meta_data": {
    "created_at": "2025-11-15T10:30:00.000Z",
    "device_model": "iPhone 15 Pro",
    "device_id": "ABC123DEF456"
  },
  "tables": {
    "stories": [{ "id": "...", "title": "...", "updatedAt": "..." }],
    "tags": [...],
    "events": [...],
    "templates": [...],
    "assets": [...],
    "preferences": [...],
    "relax_sound_mixes": [...]
  }
}
```

**Filename Format (v2)**: `Backup::2::{timestamp}::{device_model}::{device_id}`
**Filename Format (v1)**: `Backup::v1::{timestamp}::{device_model}.json`
**Compression**: GZIP compressed (v2) or uncompressed JSON (v1)
**Location**: Google Drive App Data folder (hidden from user)
**Note**: Legacy format - contains ALL records from ALL years in single file. No longer created by current app versions.

### Asset Backup

Assets (images/audio) are stored separately:

```dart
asset.cloudDestinations['google_drive'][userEmail] = {
  'file_id': 'drive_file_id_123',
  'file_name': '1701234568000.m4a'
}
```

- Upload triggered when `asset.needBackup = true`
- Original files retained in Google Drive
- Can be re-downloaded if local file deleted

## Error Scenarios

| Scenario         | Detection                         | Handling                | UI Message                                   |
| ---------------- | --------------------------------- | ----------------------- | -------------------------------------------- |
| Token Expiration | 401 responses                     | Auto reauthentication   | "Session expired. Please sign in again."     |
| Token Revocation | 403 responses                     | Auto sign-out           | "Access revoked. Please sign in again."      |
| Network Issues   | SocketException, TimeoutException | Auto retry with backoff | "Network error. Check connection and retry." |
| Quota Exceeded   | Drive API errors                  | No retry, notify user   | "Drive storage full. Free up space."         |
| Rate Limiting    | 429 responses                     | Retry with delays       | "Too many requests. Wait and retry."         |

## Usage Pattern

### In ViewModels/Providers

```dart
// Sign in with Google
final result = await backupRepository.signIn();

result.when(
  success: (data) => handleSuccess(data),
  failure: (error) => showError(error.message),
  partialSuccess: (data, errors) => handlePartial(data, errors),
);
```

### Manual Restore

```dart
// Force restore from backup (overwrites local data)
await RestoreBackupService.appInstance.forceRestore(backup: backupObject);

// Selective restore (only newer records)
int changesCount = await RestoreBackupService.appInstance.restoreOnlyNewData(
  backup: backupObject,
);
```

### Checking Sync Status

```dart
Consumer<BackupProvider>(
  builder: (context, provider, child) {
    if (provider.synced) {
      return Icon(SpIcons.check_circle); // Everything in sync
    } else if (provider.syncing) {
      return CircularProgressIndicator(); // Sync in progress
    } else {
      return Icon(SpIcons.cloud_upload); // Needs sync
    }
  },
)
```

### Monitoring Progress

```dart
// Listen to step messages
Consumer<BackupProvider>(
  builder: (context, provider, child) {
    final step1 = provider.step1Message; // Image upload progress
    final step2 = provider.step2Message; // Checking latest backup
    final step3 = provider.step3Message; // Importing changes
    final step4 = provider.step4Message; // Uploading new backup

    return Column(
      children: [
        _buildStepIndicator('Upload Assets', step1),
        _buildStepIndicator('Check Latest', step2),
        _buildStepIndicator('Import Changes', step3),
        _buildStepIndicator('Upload Backup', step4),
      ],
    );
  },
)
```

## Test Files

- `test/core/exceptions/backup_exceptions_test.dart` - All exception types
- `test/core/types/backup_result_test.dart` - Result pattern tests
- `test/core/utils/retry_policy_test.dart` - Retry logic tests
- `test/core/services/google_drive_client_test.dart` - Drive API tests

## Key Features

- **Type-safe error handling** - No throws, use `BackupResult<T>`
- **Auto retry** - Exponential backoff with jitter
- **Auth handling** - Token refresh, auto sign-out on revocation
- **User-friendly** - Clear error messages, offline support
- **Multi-device sync** - Timestamp-based conflict resolution
- **Asset backup** - Separate handling for images/audio files
- **Compression** - GZIP for efficient storage
- **Progress tracking** - Real-time UI updates via streams

## Implementation Checklist

When adding new features that need backup:

- [ ] Add model to `BackupRepository.databases` list
- [ ] Ensure model has `updatedAt` field for conflict resolution
- [ ] Test restore flow with `RestoreBackupService`
- [ ] Verify serialization/deserialization works
- [ ] Add analytics tracking if needed
- [ ] Update backup version if schema changes

## Common Issues & Solutions

### Backup Not Syncing

**Check**: `BackupProvider.connectionStatus`

- `noInternet`: Wait for connection
- `needGoogleDrivePermission`: Call `requestScope()`
- `readyToSync`: Should auto-sync

### Assets Not Uploading

**Check**: `asset.needBackup` flag

- Set to `true` when new asset created
- Step 1 only uploads assets with this flag
- Flag cleared after successful upload

### Outdated Data After Sync

**Check**: Timestamp comparison logic

- Ensure `updatedAt` is set correctly on record changes
- Verify device clocks are accurate
- Check `RestoreBackupService.restoreOnlyNewData()` logic

### Google Sign-In Fails

**Check**:

- iOS: `Info.plist` has correct URL scheme
- Android: SHA-1 fingerprint registered in Firebase
- Scopes requested: `drive.appdata` scope
- User has Google account on device

## Related Documentation

- [File Organization](./file-organization.md) - Project structure
- [Architecture](./architecture.md) - Overall app architecture
- [iOS Config](../development/ios-config.md) - Platform setup
- [Android Config](../development/android-config.md) - Platform setup
