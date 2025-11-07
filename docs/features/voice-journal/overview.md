# Voice Journal Feature - Technical Overview

## 💰 Feature Pricing: $1.99 (One-time purchase)

---

## ✅ Status: Database Infrastructure Complete

The foundation for voice recording is now in place. The database layer has been extended to support flexible asset types with metadata storage.

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
  static bool isValidAssetLink(String link);
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
  String get link => type.buildEmbedLink(id);
  // Returns: "storypad://audio/123" or "storypad://assets/123"

  // Helper for storage path (delegates to AssetType)
  String get downloadFilePath {
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
    required String assetLink,
  }) async {
    final id = AssetType.parseAssetId(assetLink);
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

✅ Query filtering by type:

```dart
// Fetch only audio files
final audioAssets = await assetsBox.getAll(filters: {"type": AssetType.audio});

// Fetch only images (includes null for backward compatibility)
final images = await assetsBox.getAll(filters: {"type": AssetType.image});

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

## 🔄 Data Flow

### Recording & Saving (Ready to implement)

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
   • downloadFilePath: ".../audio/..." (via type.getStoragePath())
   ↓
7. asset.save() → ObjectBox (type converted to 'audio' string)
   ↓
8. Embed in Quill: BlockEmbed.audio(asset.link)
   → asset.link uses type.buildEmbedLink(id)
   → Creates "storypad://audio/123"
   ↓
9. Story.assets collection updated via StoryExtractAssetsFromContentService
   ↓
10. Asset automatically queued for Google Drive backup
```

### Playing Back (Ready to implement)

```
Quill Editor renders SpAudioBlockEmbed
  ↓
Display: [▶] Duration
  ↓
Tap to play
  ↓
Load audio from asset.downloadFilePath
  ↓
JustAudio player handles playback
  ↓
Continue journaling while audio plays
```

### Backup to Google Drive (Automatic)

```
Same mechanism as images:
1. InsertFileToDbService marks asset.needBackup = true
2. BackupService uploads to Google Drive
3. cloudDestinations['google_drive'][email] = {
     'file_id': 'drive_file_id',
     'file_name': '1701234568000.m4a'
   }
4. Persisted in asset.metadata
```

---

## ✨ Why Users Will Pay $1.99

1. **Emotional Connection** - Hear your own voice in past entries
2. **Accessibility** - For people who prefer speaking to typing
3. **Memory Fidelity** - Tone, emotion, pauses preserved in recordings
4. **Quick Capture** - Record thoughts faster than typing
5. **Private Journaling** - Intimate audio format for personal reflection
6. **Complementary** - Pairs well with Relaxing Sounds add-on

---

## 🎯 Implementation Roadmap

### Phase 1: Core Recording (Next)

- [ ] Implement `VoiceRecorderService` wrapper around `record` package
- [ ] Create `SpAudioBlockEmbed` widget for playback
- [ ] Add recording button to Quill toolbar
- [ ] Wire up start/stop recording flow
- [ ] Test end-to-end: record → embed → play → backup
- [ ] Verify Google Drive backup with audio files

### Phase 2: Enhanced UX (Future)

- [ ] Waveform visualization during playback
- [ ] Pause/resume during recording
- [ ] Trim recordings
- [ ] Audio level meter during recording
- [ ] Re-record option

### Phase 3: Smart Features (Future - Premium)

- [ ] Auto-transcription (Whisper API)
- [ ] Transcription editing UI
- [ ] Sentiment detection from voice
- [ ] Voice-to-text search indexing

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
| `ios/Runner/Info.plist`                          | Microphone permission                          |
| `android/AndroidManifest.xml`                    | Microphone permissions                         |
| `pubspec.yaml`                                   | `record: ^6.1.2` package dependency            |
