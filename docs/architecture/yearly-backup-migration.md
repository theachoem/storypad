# Yearly Backup Migration Plan

## Overview

Migrate from single-file backup strategy to yearly backup files to improve performance and scalability.

## Critical Design Constraints

### 1. **Year Assignment Rule** (IMMUTABLE)

- **Rule**: Records belong to the year they were **CREATED** (`createdAt.year`), NOT updated
- **Rationale**: Prevents records from moving between backup files as they're edited
- **Implication**: A story created in 2023 stays in the 2023 backup forever

### 2. **Sync Detection Rule** (TIMESTAMP-BASED)

- **Rule**: Use `updatedAt` timestamp to determine if a year needs syncing
- **Rationale**: Edits to old records trigger sync for their creation year
- **Implication**: Editing a 2023 story in 2025 triggers 2023 backup sync

### 3. **Atomic Upload Rule** (NO RACE CONDITIONS)

- **Rule**: Use Google Drive `update(fileId)` API with stable file ID, never delete + create
- **Rationale**: Prevents race conditions when multiple devices upload simultaneously
- **Implication**:
  - Last write wins at file level (Google Drive guarantees atomicity)
  - Record-level merge still applies (timestamp-based conflict resolution)
  - File ID remains constant, only content and filename change
  - No risk of duplicate files or lost uploads

### 4. **Performance Rule** (INDEXED QUERIES)

- **Rule**: All year-based queries must use database indexes
- **Rationale**: Avoid loading thousands of records into memory
- **Implication**: Requires database migration to add indexes

### 5. **Migration Safety Rule** (ALL-OR-NOTHING)

- **Rule**: Delete v2 backup only after ALL v3 yearly backups uploaded successfully
- **Rationale**: Failed migration should be retryable without data loss
- **Implication**: Temporary storage overhead during migration

### User Experience Guarantees

✅ **Existing Users** (on update):

- One-time migration from v2 to v3 on first sync after update
- Migration is automatic and transparent
- Can retry if migration fails
- v2 backup deleted only after successful v3 migration

✅ **New Users**:

- Start with v3 directly (no migration needed)
- Faster syncs from day one
- Scales indefinitely with app usage
- No performance degradation over years
- Lower bandwidth usage

## Problem Statement

**Current System (Version 2)**:

- One backup file contains ALL records from ALL years
- File size grows indefinitely with usage
- Upload/download/processing time increases linearly
- GZIP compression helps but doesn't solve core issue

**Issues**:

- 5 years of data = potentially 50MB+ compressed file
- Every sync requires uploading entire history
- Slow for users with years of data
- Network bandwidth waste

## Proposed Solution

**Yearly Backup Strategy (Version 3)**:

- Separate backup file per year (based on record `createdAt.year`)
- Only sync years that have changes (tracked by local metadata)
- Faster individual file operations
- Better scalability for long-term users

**Key Design Decisions**:

- ✅ **Year Assignment**: Records assigned to years based on `createdAt.year` (immutable)
- ✅ **Timestamp Tracking**: Use `updatedAt` to determine if year needs sync
- ✅ **Atomic Uploads**: Use Google Drive's update API instead of delete-then-upload
- ✅ **Smart Discovery**: Track synced years locally to avoid unnecessary queries
- ✅ **Efficient Queries**: Use database indexes on `createdAt.year` for filtering

**Benefits**:

- ✅ Faster sync (only changed years upload)
- ✅ Smaller individual files
- ✅ Better network efficiency
- ✅ Scales indefinitely
- ✅ Easier to view/restore specific year
- ✅ Less memory usage during processing

## File Format Changes

### Current Format (v2)

```
Filename: Backup::2::1731680400000::iPhone 15 Pro::ABC123.zip
Contains: All records from all years
Location: appDataFolder root
```

### New Format (v3) - Year-Based with Timestamp & Device Tracking

**Solution**: Single file per year with timestamp and last-syncing device ID.

```
Google Drive Structure:
  appDataFolder/
    ├── images/                                        ← Existing: Image assets
    ├── audio/                                         ← Existing: Audio assets
    └── backups/                                       ← NEW: v3 yearly backups folder
        ├── Backup::3::2025::1734350000000::iPhone123.zip
        ├── Backup::3::2024::1704067200000::iPad456.zip
        └── Backup::3::2023::1672531200000::iPhone123.zip

Note: v2 backups (Backup::2::...) are migrated to v3 format and deleted
```

**Filename Format**: `Backup::3::{year}::{lastUpdatedAtTimestamp}::{deviceId}.zip`

**Example**: `Backup::3::2025::1734350000000::iPhone123.zip`

- `3` = Version 3 (yearly backup format)
- `2025` = Year of data (based on `createdAt.year`)
- `1734350000000` = Last update timestamp (max `updatedAt` for records in 2025)
- `iPhone123` = Device ID that last uploaded this backup

**Key Changes**:

- One file per year (all devices merge into same file)
- Organized in `backups/` subfolder (separate from assets)
- Timestamp = last update time of any record in that year (from database)
- Device ID = tracks which device performed the last upload (audit trail)
- Version bumped to `3`

**Multi-Device Sync Strategy**:

1. List all yearly backup files: Query for `name contains 'Backup::3::'` in `backups/` folder
2. For each year with local changes, check if remote backup exists
3. Compare timestamps to determine if sync needed:
   - **If remote timestamp > local timestamp**: Download and merge remote changes
   - **If local timestamp > remote timestamp**: Upload new backup with updated timestamp and current device ID
   - **If timestamps equal**: Already in sync, skip this year
4. When uploading, use `max(all local record updatedAt for this year)` as filename timestamp
5. Device ID in filename shows which device last uploaded (for debugging/audit trail)

**Benefits**:

- ✅ **Simple Naming**: Clear year-based organization in filename
- ✅ **Sync Status**: Timestamp shows when year was last synced across all devices
- ✅ **Single Source of Truth**: One file per year (all devices converge to it)
- ✅ **Automatic Discovery**: List files matching pattern `Backup::3::*` in `backups/` folder
- ✅ **Easy Multi-Device**: All devices can read and write same year file
- ✅ **Conflict-Free**: Timestamp-based merge (record level, not file level)
- ✅ **Audit Trail**: Device ID shows which device last synced (debugging & user visibility)
- ✅ **Organized**: Backups separate from assets (images/, audio/)
- ✅ **Efficient Discovery**: Only fetch file metadata (no content download) to determine sync status

## Sync Flow Scenarios

#### Scenario 1: First Sync (New User)

```
User installs app → Creates records in 2025 → Triggers backup
├─ Repository: Get years with data = [2025]
├─ Google Drive: Check if 2025 backup exists → No
├─ Repository: Generate backup for 2025
├─ Google Drive: Upload Backup::3::2025::{timestamp}::{deviceId}.zip
└─ Result: ✅ 2025 backup created
```

#### Scenario 2: Incremental Sync (Updated Old Record)

```
User edits 2023 story on Dec 15, 2025
├─ Repository: Get years with changes since last sync = [2023]
├─ Google Drive: Check 2023 backup timestamp
│   ├─ Remote: 1672531200000 (older)
│   └─ Local: 1734220800000 (newer - just edited)
├─ Repository: Generate updated 2023 backup
├─ Google Drive: Upload via update() API (atomic)
└─ Result: ✅ Only 2023 backup synced, not 2024/2025
```

#### Scenario 3: Multi-Device Sync

```
Device A (iPhone) creates Story #1 in 2025
├─ Upload: Backup::3::2025::1734340000000::iPhone123.zip

Device B (iPad) syncs 2 hours later
├─ Download: Backup::3::2025::1734340000000::iPhone123.zip
├─ Merge: Import Story #1
├─ Create: Story #2 locally
├─ Upload: Backup::3::2025::1734352000000::iPad456.zip (newer timestamp)

Device A syncs again
├─ Check: Remote timestamp > Local timestamp
├─ Download: Backup::3::2025::1734352000000::iPad456.zip
├─ Merge: Import Story #2
└─ Result: ✅ Both devices have Story #1 + Story #2
```

#### Scenario 4: Migration from v2 to v3 (One-Time)

```
User updates app with 3 years of local data → First sync triggers migration
├─ Check: Migration flag → Not migrated yet
├─ Query local database: Get all years with data (based on createdAt.year)
│   ├─ 2023: 850 records
│   ├─ 2024: 1,100 records
│   └─ 2025: 420 records
├─ Generate & upload v3 backups directly from local data:
│   ├─ Backup::3::2023::{max_timestamp_2023}::{deviceId}.zip ✅
│   ├─ Backup::3::2024::{max_timestamp_2024}::{deviceId}.zip ✅
│   └─ Backup::3::2025::{max_timestamp_2025}::{deviceId}.zip ✅
├─ Mark: Migration complete (set local flag)
└─ Result: ✅ User now on v3, future syncs use yearly backups

Note: Migration happens once per user on first sync after app update
      Local data is used directly (no download needed)
      Old v2 backups remain in Google Drive (can be restored via dedicated UI)
      Users who don't update stay on v2 (no sync with v3 users)
```

## How Sync Works

**Single file per year, timestamp-based sync**:

```
Google Drive (backups/ folder):
  Backup::3::2025::1734350000000::iPhone123.zip   ← Latest merge of all 2025 data (last uploaded by iPhone)
  Backup::3::2024::1704067200000::iPad456.zip     ← Latest merge of all 2024 data (last uploaded by iPad)
  Backup::3::2023::1672531200000::iPhone123.zip   ← Latest merge of all 2023 data (last uploaded by iPhone)
```

### Efficient Sync Algorithm

**Step 1: Fetch Remote Metadata (No Content Download)**

```
API Call: files.list(q="name contains 'Backup::3::'", fields="files(id,name,modifiedTime)")
Response: [
  { id: "abc123", name: "Backup::3::2025::1734350000000::iPhone123.zip" },
  { id: "def456", name: "Backup::3::2024::1704067200000::iPad456.zip" },
  { id: "ghi789", name: "Backup::3::2023::1672531200000::iPhone123.zip" }
]
Parse: Extract year + timestamp + fileId for each
```

**Step 2: Check Local Changes**

```
Database Query: SELECT created_year, MAX(updated_at) FROM records
                WHERE updated_at > last_sync_time
                GROUP BY created_year
Result: { 2023: 1734220800000, 2025: 1734360000000 }
```

**Step 3: Determine Actions**

```
Year 2025:
  - Remote: 1734350000000 (from filename)
  - Local:  1734360000000 (from database)
  - Action: ⬆️ Upload (local is newer) using fileId "abc123"

Year 2024:
  - Remote: 1704067200000
  - Local:  No changes
  - Action: ⏭️ Skip (no local changes)

Year 2023:
  - Remote: 1672531200000
  - Local:  1734220800000
  - Action: ⬆️ Upload (local is newer) using fileId "ghi789"

Year 2022:
  - Remote: Not found
  - Local:  New records created
  - Action: 🆕 Create new backup file
```

**Step 4: Execute Uploads**

```
For Year 2025:
  API Call: files.update(fileId="abc123", media=backup_content)
  New Filename: Backup::3::2025::1734360000000::iPad456.zip (atomic update)

For Year 2023:
  API Call: files.update(fileId="ghi789", media=backup_content)
  New Filename: Backup::3::2023::1734220800000::iPad456.zip (atomic update)

For Year 2022:
  API Call: files.create(media=backup_content, parents=["backups/"])
  New Filename: Backup::3::2022::1734220000000::iPad456.zip (new file)
```

**Key Efficiency Gains:**

- ✅ Only metadata fetched initially (lightweight ~1KB vs 2-15MB per file)
- ✅ Only changed years uploaded (not all years)
- ✅ File ID used for atomic updates (no delete+create race condition)
- ✅ Database indexed queries (fast year filtering)
- ✅ Skip unchanged years automatically

### Race Condition Prevention

**Problem**: Two devices upload same year backup simultaneously

**Solution**: Use Google Drive's atomic `update()` API with file ID

```
Scenario: Device A and Device B both edit 2025 records at same time

11:00:00 AM - Device A starts upload
├─ Fetches file list: Backup::3::2025::1734340000000::iPhone123.zip (fileId: "abc123")
├─ Prepares backup with timestamp: 1734350000000
├─ Calls: files.update(fileId="abc123", media=...)

11:00:05 AM - Device B starts upload (overlapping)
├─ Fetches file list: Backup::3::2025::1734340000000::iPhone123.zip (fileId: "abc123")
├─ Prepares backup with timestamp: 1734352000000
├─ Calls: files.update(fileId="abc123", media=...)

11:00:08 AM - Result
├─ Google Drive handles conflict: Last write wins (Device B)
├─ File now: Backup::3::2025::1734352000000::iPad456.zip
└─ No data loss: Both devices will sync again and merge records

11:00:30 AM - Device A syncs again
├─ Detects: Remote timestamp (1734352000000) > Local timestamp (1734350000000)
├─ Downloads: Backup::3::2025::1734352000000::iPad456.zip
├─ Merges: Imports Device B's records (record-level merge by updatedAt)
└─ Result: ✅ Both devices have all records
```

**Why This Works:**

1. **Atomic File Operations**: `update(fileId)` is atomic - no partial writes
2. **File ID Stability**: File ID stays same ("abc123"), only content/name changes
3. **No Delete+Create**: Avoids race where file could be deleted between operations
4. **Record-Level Merge**: Even if file-level "last write wins", record-level merge ensures no data loss
5. **Self-Healing**: Next sync automatically detects and merges missing records

**Alternative Approach (NOT USED):**

```
❌ BAD: Delete old file → Create new file
Risk: Device A deletes, Device B tries to update → 404 error
Risk: Both devices create new files → Duplicate backups

✅ GOOD: Update existing file by ID
Result: One canonical file, atomic operation, predictable behavior
```

**Edge Case Handling:**

| Scenario                           | Handling                                                     |
| ---------------------------------- | ------------------------------------------------------------ |
| File deleted manually              | Create new file (detected as "not found")                    |
| File ID invalid (Google Drive bug) | Re-fetch file list, get new ID, retry                        |
| Network interruption during upload | Retry with exponential backoff                               |
| Upload succeeds but rename fails   | File uploaded but old filename → Next sync detects and fixes |

When a device syncs:

1. **Fetch Remote Metadata** (lightweight, no content download):

   - List all yearly backup files matching `Backup::3::*` in `backups/` folder
   - Only fetch file metadata: `name`, `id`, `modifiedTime` (no file content downloaded)
   - Parse filename to extract: year, timestamp, device ID

2. **Identify Local Changes**:

   - Query local database for years with changes since last sync
   - Get max `updatedAt` timestamp per changed year (indexed query)

3. **Compare & Decide** (for each year):

   - If **year has no remote backup**: Upload new backup → Create new file
   - If **remote timestamp > local**: Download and merge remote changes
   - If **local timestamp > remote**: Upload using file ID → Update existing file (atomic)
   - If **timestamps equal**: Already in sync, skip this year

4. **Upload Strategy**:
   - **If file exists**: Use `update(fileId)` API (atomic, prevents race conditions)
   - **If file doesn't exist**: Use `create()` API to create new file
   - Filename includes: `max(all local record updatedAt for this year)` + current device ID
   - File ID remains stable across updates (only content and filename change)
   - **Critical**: Never use delete + create pattern (causes race conditions)

## Multi-Device Sync Example

**Scenario**: 3 devices sync over time

```
11:00 AM - Device A (iPhone, deviceId: iPhone123)
├─ Creates Story #1, Tag #1
├─ Local max: 1734340000000 (11:00 AM)
└─ Uploads: Backup::3::2025::1734340000000::iPhone123.zip

2:00 PM - Device B (iPad, deviceId: iPad456)
├─ Fetches: Backup::3::2025::1734340000000::iPhone123.zip
├─ Sees: Last synced by iPhone
├─ Merges: Imports Story #1, Tag #1
├─ Creates: Story #2
├─ Local max: 1734352000000 (2:00 PM, newer)
└─ Uploads: Backup::3::2025::1734352000000::iPad456.zip (overwrites previous, now shows iPad as last sync device)

4:00 PM - Device A (iPhone) syncs again
├─ Checks: Remote timestamp 1734352000000 > Local timestamp 1734340000000
├─ Downloads: Backup::3::2025::1734352000000::iPad456.zip
├─ Sees: Last synced by iPad (helpful for debugging)
├─ Merges: Imports Story #2 from iPad
└─ All devices now have Story #1, Story #2, Tag #1 ✅

4:30 PM - Device C (Mac, deviceId: Mac789) first sync
├─ Discovers: Available years = [2025]
├─ Downloads: Backup::3::2025::1734352000000::iPad456.zip
├─ Sees: Last synced by iPad
├─ Merges: Imports Story #1, Story #2, Tag #1
├─ Has local data: Event #1 (created on Mac)
├─ Local max: 1734354600000 (4:30 PM, newest)
└─ Uploads: Backup::3::2025::1734354600000::Mac789.zip (now shows Mac as last sync device)
```

**Result**: All 3 devices eventually have all data, filename shows which device last synced

## Migration Strategy

### High-Level Migration Flow

**One-Time Automatic Migration** (on first sync after app update)

1. Check migration flag in local preferences
2. If not migrated yet:
   - Query local database for all years with data (grouped by `createdAt.year`)
   - Generate yearly v3 backups directly from local data
   - Upload yearly v3 backups to `backups/` folder
   - Set migration flag (prevents re-migration)
3. If migration fails midway:
   - Retry on next app launch
   - Continue retrying until successful

**Important Notes:**

- ⚠️ **No backward compatibility**: Users must update app to sync
- ⚠️ **Cross-device migration**: All user's devices need app update eventually
- ✅ **No download needed**: Uses local data directly (faster migration)
- ✅ **Self-healing**: Failed migrations auto-retry transparently
- ✅ **v2 backups preserved**: Old v2 backups remain in Google Drive for manual restore if needed

### Legacy Backup Management (v2)

**UI Plan: Dedicated Restore Screen**

Add a "Legacy Backups" section in settings/backup screen to:

1. **List v2 Backups**

   - Show all available v2 backups in Google Drive root
   - Display: Filename, date, device name, file size
   - Sort by date (newest first)

2. **Restore Options**

   - Button: "Restore from Legacy Backup"
   - Warning: "This will download and merge data from v2 backup"
   - Confirmation dialog with backup details

3. **Delete Options** (optional)
   - Allow users to manually delete old v2 backups
   - Warning: "Once deleted, cannot be recovered"
   - Confirmation with backup name

**Benefits:**

- ✅ Safety net for users (can recover from v2 if needed)
- ✅ User control over storage cleanup
- ✅ Transparency (users see what's in their Google Drive)
- ✅ Emergency recovery option

### Migration Safeguards

✅ **Atomic**: All v3 uploads must succeed before marking migration complete  
✅ **Retryable**: Failed migration can retry on next launch  
✅ **Validated**: Check backup structure before processing  
✅ **Graceful**: Handle partial migrations (some years uploaded)  
✅ **Logged**: Detailed error messages for debugging
✅ **v2 Preserved**: Old v2 backups kept in Google Drive (manual restore available)

## Performance Benchmarks

Expected improvements over v2:

| Metric                | v2 (Current) | v3 (Yearly)        | Improvement    |
| --------------------- | ------------ | ------------------ | -------------- |
| Avg file size         | 15 MB        | 2-3 MB/year        | 5-7x smaller   |
| Upload time (3 years) | 45s          | 15s (changed only) | 3x faster      |
| Download time         | 30s          | 10s (per year)     | 3x faster      |
| Processing time       | 8s           | 2s (per year)      | 4x faster      |
| Sync frequency        | All data     | Changed years only | ~10x less data |

## Summary

### Problem Solved

Single monolithic backup file grows indefinitely → Separate yearly backups for better performance and scalability.

### Benefits

✅ Faster sync (only changed years upload)
✅ Smaller individual files (2-3 MB vs 15 MB+)
✅ Better network efficiency
✅ Scales indefinitely
✅ Easier year-specific restore

### Core Design

- **File Format**: `Backup::3::{year}::{timestamp}::{deviceId}.zip`
- **Storage**: `appDataFolder/backups/` folder (organized, separate from assets)
- **Assignment**: Records assigned by `createdAt.year` (immutable)
- **Sync Detection**: Compare timestamps (local vs remote)
- **Upload**: Atomic `update()` API (no race conditions)
- **Queries**: Database indexes for performance

### Migration Strategy

1. On first sync after app update, check for migration flag
2. Query local database for all years with data (by `createdAt.year`)
3. Generate yearly v3 backups directly from local data
4. Upload v3 backups to `backups/` folder
5. Set migration flag (prevents re-migration)
6. Retry on failure until successful

**Important:**

- Old v2 backups remain in Google Drive (not deleted automatically)
- Users can restore from v2 via dedicated "Legacy Backups" UI screen
- Users can manually delete v2 backups when they're confident v3 is working

**User Impact:**

- Users must update app to continue syncing
- One-time migration on first sync (automatic, uses local data)
- No backward compatibility with v2
- v2 backups preserved as safety net

### Risk Level

**MEDIUM** (with mitigations in place)

### Recommendation

**PROCEED** with phased rollout and close monitoring.
