# Voice Journal Feature - Technical Overview

## 💰 Feature Pricing: $1.99 (One-time purchase)

---

## ✅ Status: COMPLETE & SHIPPED 🚀

The Voice Journaling feature is fully implemented and live in production! Users can record voice notes, organize them by tags, and play them back seamlessly.

---

## 📐 Architecture

### Asset System Design

```
┌────────────────────────────────────────┐
│  Story Content (Quill Editor)          │
│  • BlockEmbed.image() ✅               │
│  • BlockEmbed.audio() ← NEW            │
│  • BlockEmbed.date()                   │
└────────────────┬─────────────────────┘
                 │
                 ↓
┌────────────────────────────────────────┐
│  AssetDbModel (Application Layer)      │
│  ✅ type: 'image' | 'audio'            │
│  ✅ metadata: Map<String, dynamic>     │
│  ✅ isAudio, isImage (getters)         │
│  ✅ durationInMs, formattedDuration    │
│  ✅ link (storypad://audio/id)         │
│  ✅ downloadFilePath (routes audio/)   │
└────────────────┬───────────────────────┘
                 │
         (JSON Encoding/Decoding)
                 │
                 ↓
┌────────────────────────────────────────┐
│  AssetObjectBox (Database Layer)       │
│  ✅ type: String? ('image', 'audio')   │
│  ✅ metadata: String? (JSON)           │
│  • originalSource                      │
│  • cloudDestinations                   │
└────────────────┬───────────────────────┘
                 │
                 ↓
         ObjectBox Storage
```

---

## 📁 File Storage

```
Device Storage:
  kSupportDirectory/
    ├── images/
    │   ├── 1701234567890.jpg     ✅ Existing
    │   └── 1701234567891.jpeg
    └── audio/                     ✅ NEW
        ├── 1701234568000.m4a      Voice recordings
        ├── 1701234568001.m4a
        └── 1701234568002.m4a

Google Drive Backup:
  Same directory structure, automatic sync
```

---

## 📝 Implemented Changes

### 0. **AssetType Enum** (`lib/core/types/asset_type.dart`) ✨ NEW

Central type system for all asset types with built-in URI and storage path management:

```dart
enum AssetType {
  image(embedLinkPath: 'assets', subDirectory: 'images'),
  audio(embedLinkPath: 'audio', subDirectory: 'audio');

  final String embedLinkPath;  // URI scheme path
  final String subDirectory;    // Storage directory name

  // URI prefix: "storypad://assets/" or "storypad://audio/"
  String get embedLinkPrefix => 'storypad://$embedLinkPath/';

  // Build complete link: "storypad://audio/123"
  String buildEmbedLink(int id) => '$embedLinkPrefix$id';

  // Get storage path: "/support/audio/123.m4a"
  String getStoragePath({required int id, required String extension});

  // Parse ID from link: "storypad://audio/123" → 123
  int? parseAssetIdFromLink(String link);

  // Static helpers
  static int? parseAssetId(String link);  // Works with any type
  static AssetType? getTypeFromLink(String link);
  static bool isValidAssetLink(String link);  // Check if string is valid asset link
  static List<String> get allEmbedLinkPrefixes;  // All supported URI schemes
  static AssetType fromValue(String? value);  // For JSON
}
```

**Benefits:**

- Single source of truth for asset type configuration
- Type-safe enum instead of string constants
- Automatic URI scheme and storage path generation
- Easy to add new asset types (just add enum value)
- Backward compatible with existing image links

### 1. **AssetObjectBox** (`lib/core/databases/adapters/objectbox/entities.dart`)

```dart
@Entity()
class AssetObjectBox extends BaseObjectBox {
  String? type;       // 'image', 'audio', etc.
  String? metadata;   // JSON string for flexible metadata
}
```

### 2. **AssetDbModel** (`lib/core/databases/models/asset_db_model.dart`)

```dart
class AssetDbModel extends BaseDbModel {
  final AssetType type;  // Enum: AssetType.image | AssetType.audio
  final Map<String, dynamic>? metadata;

  // Getters
  bool get isAudio => type == AssetType.audio;
  bool get isImage => type == AssetType.image;
  int? get durationInMs => metadata?['duration_in_ms'] as int?;
  String? get formattedDuration; // Returns "MM:SS" format

  // Smart link routing using AssetType enum
  String get embedLink => type.buildEmbedLink(id);
  // Returns: "storypad://audio/123" or "storypad://assets/123"

  // Helper for storage path (delegates to AssetType)
  String get localFilePath {
    return type.getStoragePath(
      id: id,
      extension: extension(originalSource),
    );
  }

  // Create audio asset with duration
  static AssetDbModel fromLocalPath({
    required int id,
    required String localPath,
    required AssetType type,  // Required enum type
    int? durationInMs,
  }) { ... }

  // Update duration later
  AssetDbModel copyWithDuration(int durationInMs) { ... }

  // Find asset by URI link (uses AssetType.parseAssetId)
  static Future<AssetDbModel?> findBy({
    required String embedLink,
  }) async {
    final id = AssetType.parseAssetId(embedLink);
    return id != null ? AssetDbModel.db.find(id) : null;
  }
}
```

### 3. **AssetsBox** (`lib/core/databases/adapters/objectbox/assets_box.dart`)

✅ Encoding/Decoding layer for JSON ↔ Map conversion

- `modelToObject()`: AssetDbModel (Map) → AssetObjectBox (JSON string)
  - Converts `AssetType` enum → string (`type.name`)
  - Converts `metadata` Map → JSON string
- `objectToModel()`: AssetObjectBox (JSON string) → AssetDbModel (Map)
  - Converts string → `AssetType` enum (`AssetType.fromValue()`)
  - Converts JSON string → `metadata` Map

✅ Query filtering by type and tags:

```dart
// Fetch only audio files
final audioAssets = await assetsBox.getAll(filters: {"type": AssetType.audio});

// Fetch only images (includes null for backward compatibility)
final images = await assetsBox.getAll(filters: {"type": AssetType.image});

// Filter by tag
final taggedAssets = await assetsBox.getAll(filters: {
  "type": AssetType.audio,
  "tag": tagId,
});

// Fetch by IDs
final assets = await assetsBox.getAll(filters: {"ids": [1, 2, 3]});
```

### 4. **InsertFileToDbService** (`lib/core/services/insert_file_to_db_service.dart`)

✅ Extended with audio support:

```dart
// Original method for images
static Future<AssetDbModel?> insertImage(XFile file, Uint8List fileBytes)

// New method for audio
static Future<AssetDbModel?> insertAudio(
  String filePath,
  Uint8List fileBytes,
  {int? durationInMs}
) {
  // Stores in /audio/{timestamp}.m4a
  // Auto-captures duration in metadata
}
```

### 5. **Story Asset Extraction** (`lib/core/services/stories/story_extract_assets_from_content_service.dart`)

✅ Service automatically extracts asset links from story content:

- Supports both `storypad://assets/` (images) and `storypad://audio/` (audio)
- Uses `AssetType` enum for scheme-based extraction
- Universal embed discovery (works with any future embed type)
- Internally uses `AssetLinkParser` utility for Quill Delta parsing

```dart
// Get all image links
final imageLinks = StoryExtractAssetsFromContentService.images(content);
// Returns: ["storypad://assets/123", ...]

// Get all audio links
final audioLinks = StoryExtractAssetsFromContentService.audio(content);
// Returns: ["storypad://audio/456", ...]

// Get all asset links
final allLinks = StoryExtractAssetsFromContentService.all(content);
// Returns: ["storypad://assets/123", "storypad://audio/456", ...]
```

### 6. **Platform Permissions** ✅

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to your microphone to record voice notes for your stories.</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

**Dependencies** (`pubspec.yaml`):

```yaml
record: ^6.1.2 # Cross-platform recording
```

---

## 💾 Metadata Storage Pattern

### Flexible Design (No Schema Migrations)

**Current (Audio Duration):**

```dart
metadata = {'durationInMs': 120000}
```

**Future (Transcription):**

```dart
metadata = {
  'durationInMs': 120000,
  'transcription': 'Hello, this is my voice journal entry'
}
```

**Future (Waveform Visualization):**

```dart
metadata = {
  'durationInMs': 120000,
  'waveform': [0.1, 0.2, 0.5, 0.3, ...]
}
```

**Why this works:**

- Database stores metadata as JSON string (flexible)
- Application layer uses Map (easy to manipulate)
- Add new fields without migrations
- Type-safe getters on AssetDbModel
- Backward compatible with existing images

---

## 🏷️ Asset Tagging System

### Automatic Tag Assignment

Voice recordings automatically inherit tags from their connected stories:

**Implementation (`database_initializer.dart:35` & `stories_box.dart:182`):**

```dart
// When a story is saved (StoriesBox#set)
if (saved != null && !saved.draftStory) {
  // Get all assets used in this story
  List<AssetDbModel> assets = await AssetDbModel.db
      .where(filters: {'ids': saved.assets})
      .then((e) => e?.items ?? []);

  // Compute tags for each asset
  for (int i = 0; i < assets.length; i++) {
    Set<int> tags = await computeStoriesTagsForAsset(assets[i]);
    await assets[i].copyWith(tags: tags.toList()).save();
  }
}

// computeStoriesTagsForAsset(): Finds all stories using this asset
// and collects their unique tags
Future<Set<int>> computeStoriesTagsForAsset(AssetDbModel asset) async {
  return await buildQuery(filters: {'asset': asset.id})
      .build()
      .findAsync()
      .then((stories) => stories.map((s) => s.tags).expand((tags) => tags));
}
```

**Migration for existing assets (`database_initializer.dart`):**

```dart
static Future<void> computeStoryTagsForAsset() async {
  bool initialComputed = await ComputedInitialTagsForAssetsStorage().read();

  if (!initialComputed) {
    var assets = await AssetDbModel.db.where();
    for (var asset in assets) {
      var tags = await StoryDbModel.db.computeStoriesTagsForAsset(asset);
      await asset.copyWith(tags: tags.toList()).save();
    }
    await ComputedInitialTagsForAssetsStorage().write(true);
  }
}
```

**Why this matters:**

- 🎯 **Organize recordings by topic** - Tag "Work" stories, all voice notes get "Work" tag
- 🔍 **Powerful filtering** - View all "Travel" voice notes across all trips
- 🔄 **Automatic updates** - Tags sync whenever stories are published (not drafts)
- 📊 **Zero manual work** - Users don't manage asset tags separately

---

## 📱 Voice Journal UI (COMPLETE)

### Library View with Tabs (`library_view.dart`)

```dart
DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: AppBar(
      title: Text("Library"),
      bottom: TabBar(
        tabs: [
          Tab(icon: Icon(SpIcons.photo)),   // Images tab
          Tab(icon: Icon(SpIcons.voice)),   // Voice tab ← NEW
        ],
      ),
    ),
    body: TabBarView(
      children: [
        _ImagesTabContent(),
        _VoicesTabContent(),  // ← Voice journaling interface
      ],
    ),
  ),
)
```

### Voices Tab Content (`voices_tab_content.dart`)

**Features:**

✅ **Tag Filtering** - Horizontal scrollable chips with story counts  
✅ **Grouped by Date** - "Today", "Yesterday", or date (YYYY-MM-DD)  
✅ **Cloud Backup Status** - Visual indicators for Google Drive sync  
✅ **Quick Playback** - Tap to play in bottom sheet  
✅ **Story Navigation** - View connected stories from context menu  
✅ **Smart Deletion** - Delete locally or from Google Drive

**UI Structure:**

```dart
class _VoicesTabContent extends StatefulWidget {
  // State management
  CollectionDbModel<AssetDbModel>? assets;
  Map<int, int> storiesCount;  // asset_id → story_count
  int? selectedTagId;

  // Dynamic filters
  Map<String, dynamic> get filters => {
    'type': AssetType.audio,
    'tag': selectedTagId,  // null = show all
  };

  // Real-time updates
  void initState() {
    StoryDbModel.db.addGlobalListener(_listener);
    _load();
  }

  Future<void> _load() async {
    // Fetch filtered audio assets
    assets = await AssetDbModel.db.where(filters: filters);

    // Get story counts for each asset
    storiesCount = StoryDbModel.db.getStoryCountByAssets(
      assetIds: assets.items.map((e) => e.id).toList(),
    );
  }
}
```

**Tag Filter UI:**

```dart
SpScrollableChoiceChips<TagDbModel>(
  choices: tagsProvider.tags.items,
  storiesCount: (tag) => tag.id == selectedTagId ? assets.length : null,
  toLabel: (tag) => tag.title,
  selected: (tag) => selectedTagId == tag.id,
  onToggle: (tag) {
    selectedTagId = selectedTagId == tag.id ? null : tag.id;
    _load();  // Re-fetch with new filter
  },
)
```

**Voice Item Display:**

```dart
ListTile(
  onTap: () => SpVoicePlaybackSheet(asset: asset).show(context),
  leading: Icon(SpIcons.voice),
  title: Text("3:45 PM 🟢"),  // Time + backup status
  subtitle: Row(
    children: [
      Text("02:34"),  // Duration from metadata
      if (storyCount == 0) Icon(SpIcons.archive),  // Unused warning
    ],
  ),
  trailing: PopupMenu([
    if (storyCount > 0) "View Story",
    "Info",
    if (storyCount == 0) "Delete",
  ]),
)
```

**Date Grouping Logic:**

```dart
List<Map<String, dynamic>> _groupAssetsByDay(List<AssetDbModel> assets) {
  final grouped = <String, List<AssetDbModel>>{};

  for (var asset in assets) {
    final key = _getDayKey(asset.createdAt);  // "Today", "Yesterday", or date
    grouped.putIfAbsent(key, () => []).add(asset);
  }

  // Sort newest first
  return grouped.entries
      .sortedBy((e) => _parseDateKey(e.key))
      .map((e) => {'label': e.key, 'assets': e.value})
      .toList();
}
```

### Voice Playback Sheet (`sp_voice_playback_sheet.dart`)

**Modal bottom sheet with audio player:**

```dart
class SpVoicePlaybackSheet extends BaseBottomSheet {
  final AssetDbModel asset;

  Widget build(BuildContext context) {
    return SpAudioPlayer(
      autoplay: true,
      initialDuration: Duration(milliseconds: asset.durationInMs),
      onDownloadRequested: () => _downloadFromGoogleDrive(asset),
    );
  }
}
```

### Audio Player Widget (`sp_audio_player.dart`)

**Reusable player with lifecycle management:**

```dart
class SpAudioPlayer extends StatefulWidget {
  final String? filePath;  // Local path
  final Duration? initialDuration;
  final Future<String> Function()? onDownloadRequested;  // Lazy-load callback
  final bool autoplay;

  // Features:
  // ✅ Play/pause with progress slider
  // ✅ Current time / total duration display
  // ✅ Stadium-shaped clean design
  // ✅ Auto-pause on app background
  // ✅ Supports lazy-loading (download on play)
  // ✅ AudioPlayer lifecycle management
}
```

### Asset Deletion (`library_view_model.dart`)

**Smart deletion logic:**

```dart
Future<void> deleteAsset(AssetDbModel asset, int storyCount) async {
  // Safety checks
  if (storyCount > 0) return;  // Can't delete if used in stories
  if (!hasInternet) return showSnackBar("No internet");

  // Confirm with user
  if (await showOkCancelDialog(...) == OkCancelResult.ok) {
    // Delete from Google Drive if backed up
    if (asset.isGoogleDriveUploadedFor(currentUser.email)) {
      await googleDriveClient.deleteFile(fileId);
    }

    // Delete local file and database entry
    await asset.delete();
  }
}
```

---

## 🔄 Data Flow

### Recording & Saving (IMPLEMENTED ✅)

```
1. User taps record button
   ↓
2. VoiceRecorderService.startRecording(outputPath)
   ↓
3. Records audio to /audio/{timestamp}.m4a
   ↓
4. VoiceRecorderService.stopRecording()
   → Returns VoiceRecordingResult(path, durationInMs)
   ↓
5. InsertFileToDbService.insertAudio(
     filePath, fileBytes, durationInMs
   )
   ↓
6. Creates AssetDbModel with:
   • type: AssetType.audio (enum)
   • metadata: {'durationInMs': 120000}
   • localFilePath: ".../audio/..." (via type.getStoragePath())
   ↓
7. asset.save() → ObjectBox (type converted to 'audio' string)
   ↓
8. Embed in Quill: BlockEmbed.audio(asset.embedLink)
   → asset.embedLink uses type.buildEmbedLink(id)
   → Creates "storypad://audio/123"
   ↓
9. Story.assets collection updated via StoryExtractAssetsFromContentService
   ↓
10. Asset automatically queued for Google Drive backup
```

### Playing Back (IMPLEMENTED ✅)

**From Library:**

```
User taps voice item in Library → Voices tab
  ↓
SpVoicePlaybackSheet opens (bottom sheet)
  ↓
SpAudioPlayer widget renders
  ↓
If file exists locally:
  → Load from asset.localFilePath
  ↓
Else (cloud-only):
  → Call onDownloadRequested callback
  → GoogleDriveAssetDownloaderService.downloadAsset()
  → Returns downloaded file path
  ↓
AudioPlayer.setFilePath(path)
  ↓
Autoplay: true → Starts playback immediately
  ↓
User controls: play/pause, seek, see duration
  ↓
Sheet dismissible anytime
```

**From Story (Quill Editor):**

```
Quill Editor renders SpAudioBlockEmbed
  ↓
Display: [▶] Duration (MM:SS)
  ↓
Tap to play inline
  ↓
Load audio from asset.localFilePath
  ↓
JustAudio player handles playback
  ↓
Continue journaling while audio plays in background
```

### Backup to Google Drive (IMPLEMENTED ✅)

```
Same mechanism as images:
1. InsertFileToDbService marks asset.needBackup = true
   ↓
2. BackupService detects new audio asset
   ↓
3. Uploads .m4a file to Google Drive
   ↓
4. Updates asset.cloudDestinations:
   cloudDestinations['google_drive'][email] = {
     'file_id': 'drive_file_id',
     'file_name': '1701234568000.m4a'
   }
   ↓
5. UI shows backup status badge:
   🟡 Warning (not backed up)
   🟢 Success (backed up)
   ↓
6. If local file deleted, can re-download from cloud
```

### Tag Updates (IMPLEMENTED ✅)

```
User publishes story with voice note + "Travel" tag
  ↓
StoriesBox#set() triggered
  ↓
Extract story.assets (list of asset IDs)
  ↓
For each asset:
  ↓
  Query all stories using this asset
  ↓
  Collect unique tags from all stories
  ↓
  asset.copyWith(tags: [1, 5, 12]).save()
  ↓
Library → Voices tab now shows "Travel" filter chip
  ↓
User selects "Travel" → Only shows this voice note
```

---

## ✨ Why Users Will Pay $1.99

1. **Emotional Connection** - Hear your own voice in past entries
2. **Accessibility** - For people who prefer speaking to typing
3. **Memory Fidelity** - Tone, emotion, pauses preserved in recordings
4. **Quick Capture** - Record thoughts faster than typing
5. **Private Journaling** - Intimate audio format for personal reflection
6. **Complementary** - Pairs well with Relaxing Sounds add-on
7. **Smart Organization** - Auto-tagging keeps voice notes organized
8. **Seamless Backup** - Never lose precious voice memories
9. **Cross-device Sync** - Access voice journals from any device

---

## 🎉 User Experience (LIVE IN PRODUCTION)

### Recording a Voice Note

```
1. Open story editor
2. Tap microphone button in toolbar
3. Record your thoughts (speak naturally)
4. Tap stop → Voice note embedded in story
5. Publish story → Voice gets auto-tagged
6. Background sync to Google Drive
```

### Browsing Voice Journal Library

```
1. Tap Library tab (bottom navigation)
2. Select "Voice" tab (🎤 icon)
3. See all recordings grouped by date:
   📅 Today
      🎤 3:45 PM - 02:34 🟢
      🎤 9:12 AM - 01:15 🟢
   📅 Yesterday
      🎤 7:30 PM - 03:21 🟢
   📅 2025-11-06
      🎤 2:15 PM - 00:45 🟡 (backing up...)

4. Filter by tags (horizontal chips):
   [All] [Work 3] [Travel 5] [Personal 12]

5. Tap to play immediately
6. Long-press for options:
   • View connected story
   • Asset info (size, date, backup status)
   • Delete (if unused in stories)
```

### Playback Experience

```
Tap voice item
  ↓
Bottom sheet slides up
  ↓
Audio player appears:
  ┌─────────────────────────────┐
  │   ▶  ━━━━●━━━━━━━━  02:34  │
  │      00:34        Total     │
  └─────────────────────────────┘
  ↓
Auto-plays immediately
  ↓
Drag slider to seek
  ↓
Dismiss sheet anytime (playback stops)
```

### Tag-Based Organization

```
User journey:
  ↓
Create "Work Meeting" story
  ↓
Record voice note during meeting
  ↓
Add tags: #Work #Team #Q4
  ↓
Publish story
  ↓
Voice note automatically gets tags: Work, Team, Q4
  ↓
Later: Filter Library by "Work" → See all work-related voices
```

---

## ✅ Implementation Status

### Phase 1: Core Recording ✅ COMPLETE

- ✅ `VoiceRecorderService` wrapper around `record` package
- ✅ `SpAudioBlockEmbed` widget for inline playback in stories
- ✅ `SpAudioPlayer` reusable audio player widget
- ✅ Recording button in Quill toolbar
- ✅ Start/stop/save recording flow
- ✅ End-to-end: record → embed → play → backup
- ✅ Google Drive backup for audio files
- ✅ Library tab with voice recordings list
- ✅ Tag-based filtering
- ✅ Date-grouped organization
- ✅ Cloud sync status indicators
- ✅ Delete from local & Google Drive

### Phase 2: Enhanced UX (Future)

- [ ] Waveform visualization during playback
- [ ] Pause/resume during recording
- [ ] Trim recordings
- [ ] Audio level meter during recording
- [ ] Re-record option
- [ ] Voice note thumbnails/previews

### Phase 3: Smart Features (Future - Premium Tier)

- [ ] Auto-transcription (Whisper API / On-device)
- [ ] Transcription editing UI
- [ ] Sentiment detection from voice
- [ ] Voice-to-text search indexing
- [ ] AI-powered voice summaries
- [ ] Speaker identification (multi-person journals)

---

## � Key Files

| File                                             | Purpose                                        |
| ------------------------------------------------ | ---------------------------------------------- |
| `asset_type.dart`                                | **NEW**: AssetType enum with URI/storage logic |
| `entities.dart`                                  | Added `type` and `metadata` to AssetObjectBox  |
| `asset_db_model.dart`                            | Asset model with AssetType enum, audio getters |
| `assets_box.dart`                                | JSON encoding/decoding, type filtering         |
| `insert_file_to_db_service.dart`                 | Audio file insertion method                    |
| `story_extract_assets_from_content_service.dart` | Universal asset link extraction                |
| `asset_link_parser.dart`                         | Utility for parsing Quill Delta embed links    |
| `database_initializer.dart`                      | Asset tag migration & initialization           |
| `stories_box.dart`                               | Auto-compute tags for assets on story save     |
| `library_view.dart`                              | Main library with Images/Voice tabs            |
| `voices_tab_content.dart`                        | Voice recordings list with tag filters         |
| `sp_voice_playback_sheet.dart`                   | Modal bottom sheet for playback                |
| `sp_audio_player.dart`                           | Reusable audio player widget                   |
| `library_view_model.dart`                        | Delete asset logic (local + cloud)             |
| `sp_scrollable_choice_chips.dart`                | Tag filter chips with counts                   |
| `ios/Runner/Info.plist`                          | Microphone permission                          |
| `android/AndroidManifest.xml`                    | Microphone permissions                         |
| `pubspec.yaml`                                   | `record: ^6.1.2`, `just_audio` dependencies    |
