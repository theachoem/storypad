# Platform Adaptors — Linux / FOSS Support

Extract Firebase-specific code behind adaptor interfaces so Linux/FOSS builds run without any server-side dependencies. Each Firebase service gets a base adaptor interface + a Firebase implementation + a no-op or alternative implementation.

## Scope

| Service                | Firebase Dep             | Adaptor Strategy                                                             |
| ---------------------- | ------------------------ | ---------------------------------------------------------------------------- |
| Analytics (events)     | `firebase_analytics`     | `FirebaseAnalyticsEventAdaptor` / `NoneAnalyticsEventAdaptor`                |
| Analytics (user props) | `firebase_analytics`     | `FirebaseAnalyticsUserPropertyAdaptor` / `NoneAnalyticsUserPropertyAdaptor`  |
| Error Reporting        | `firebase_crashlytics`   | `FirebaseCrashlyticsAdaptor` / `NoneErrorReportingAdaptor`                   |
| Remote Config          | `firebase_remote_config` | `FirebaseRemoteConfigAdaptor` / `NoneRemoteConfigAdaptor`                    |
| Cloud Storage          | `firebase_storage`       | `FirebaseCloudStorageAdaptor` / `CdnCloudStorageAdaptor`                     |
| Cloud Backup           | `google_sign_in`         | `GoogleDriveCloudService` (existing) / `GoogleDriveLinuxCloudService` (stub) |

## Adaptor Injection

Each base adaptor has a static `instance` that auto-selects based on `Platform.isLinux`:

```dart
static BaseAnalyticsEventAdaptor? _instance;

static BaseAnalyticsEventAdaptor get instance {
  return _instance ??= (!kIsWeb && Platform.isLinux)
      ? NoneAnalyticsEventAdaptor()
      : FirebaseAnalyticsEventAdaptor();
}
```

Flavor-specific overrides are possible by calling `SomeAdaptor.setInstance(...)` before `runApp` in `main_*.dart` entry points.

---

## 1. Analytics — Events

### Key Design

- Adaptors implement only **1 method**: `logEvent(String name, {Map<String, Object>? parameters})`
- All high-level methods (`logSearch`, `logSyncBackup`, `logSignIn`, etc.) live **once** in the base class, implemented by calling `logEvent`
- The existing `AnalyticsService` and `BaseAnalyticsService` are refactored to delegate to the adaptor

### Files

```
lib/core/services/analytics/
  adaptors/
    base_analytics_event_adaptor.dart        # abstract: logEvent() + all high-level methods
    firebase_analytics_event_adaptor.dart    # implements logEvent() via FirebaseAnalytics
    none_analytics_event_adaptor.dart        # no-op: logEvent() does nothing
  analytics_service.dart                     # refactored: all methods call adaptor.logXxx()
  base_analytics_service.dart               # keep: shared helpers (sanitize, storyParams, debug)
```

### Base Adaptor Interface

```dart
abstract class BaseAnalyticsEventAdaptor {
  // --- Only this method needs implementation in subclasses ---
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  // --- All high-level methods implemented once here ---
  Future<void> logSearch({required String searchTerm}) =>
      logEvent('search', parameters: {'search_term': searchTerm});

  Future<void> logLogin({required String loginMethod}) =>
      logEvent('login', parameters: {'method': loginMethod});

  Future<void> logSyncBackup() => logEvent('sync_backup');
  Future<void> logSignOut() => logEvent('sign_out');
  // ... all other logXxx methods
}
```

### Migration Steps

1. Create `base_analytics_event_adaptor.dart` — move all high-level methods from `AnalyticsService` to base, implemented via `logEvent()`
2. Create `FirebaseAnalyticsEventAdaptor` — extract all `FirebaseAnalytics.instance.*` calls into `logEvent()` + `logScreenView()` + `logLogin()` (Firebase has special named events for these)
3. Create `NoneAnalyticsEventAdaptor` — `logEvent()` returns `Future.value()`
4. Refactor `AnalyticsService` to call `BaseAnalyticsEventAdaptor.instance.logXxx()`

> **Note on `logScreenView` and `logLogin`**: Firebase GA4 has specific named events for these. `FirebaseAnalyticsEventAdaptor` can override them if needed; other adaptors just use the base `logEvent` fallback.

---

## 2. Analytics — User Properties

### Key Design

- Adaptors implement only **1 method**: `setUserProperty(String name, String? value)`
- All high-level methods (`logSetLocale`, `logSetThemeMode`, etc.) live once in the base class

### Files

```
lib/core/services/analytics/
  adaptors/
    base_analytics_user_property_adaptor.dart        # abstract: setUserProperty() + all high-level methods
    firebase_analytics_user_property_adaptor.dart    # implements setUserProperty() via FirebaseAnalytics
    none_analytics_user_property_adaptor.dart        # no-op
  analytics_user_propery_service.dart               # refactored: delegates to adaptor
```

### Base Adaptor Interface

```dart
abstract class BaseAnalyticsUserPropertyAdaptor {
  // --- Only this method needs implementation ---
  Future<void> setUserProperty(String name, String? value);

  // --- All high-level methods implemented once here ---
  Future<void> logSetLocale({required Locale locale}) =>
      setUserProperty('locale', locale.toLanguageTag());

  Future<void> logSetThemeMode({required ThemeMode mode}) =>
      setUserProperty('theme_mode', mode.name);
  // ...
}
```

---

## 3. Error Reporting (Crashlytics)

### Key Design

- Adaptors implement **2 methods**: `recordError()` and `recordFlutterFatalError()`
- Error filtering logic (`_isIgnorable`) lives once in the base class / service
- `FirebaseCrashlyticsInitializer` is kept but delegates to the adaptor

### Files

```
lib/core/services/error_reporting/
  adaptors/
    base_error_reporting_adaptor.dart           # abstract: recordError, recordFlutterFatalError
    firebase_crashlytics_adaptor.dart           # wraps FirebaseCrashlytics.instance
    none_error_reporting_adaptor.dart           # no-op
lib/core/initializers/
  firebase_crashlytics_initializer.dart         # refactored: uses BaseErrorReportingAdaptor.instance
```

### Base Adaptor Interface

```dart
abstract class BaseErrorReportingAdaptor {
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false});
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);

  static BaseErrorReportingAdaptor? _instance;
  static BaseErrorReportingAdaptor get instance { ... }
}
```

### Migration Steps

1. Create adaptor files above
2. Refactor `FirebaseCrashlyticsInitializer` to call `BaseErrorReportingAdaptor.instance.recordXxx()`
3. Refactor `remote_config_object.dart` to call adaptor instead of `FirebaseCrashlytics.instance` directly

---

## 4. Remote Config

### Key Design

- Adaptors implement **`initialize()`** + **typed getters** (`getString`, `getBool`, `getInt`, `getDouble`, `getJsonString`)
- `NoneRemoteConfigAdaptor` always returns the passed-in `defaultValue`
- `_RemoteConfigObject.get()` calls the adaptor instead of `remoteConfig.*` directly
- The listener/notification system stays in `RemoteConfigService`

### Files

```
lib/core/services/remote_config/
  adaptors/
    base_remote_config_adaptor.dart           # abstract: initialize + typed getters + onConfigUpdated stream
    firebase_remote_config_adaptor.dart       # wraps FirebaseRemoteConfig.instance
    none_remote_config_adaptor.dart           # returns defaultValue, empty stream
  remote_config_service.dart                  # refactored: uses adaptor for fetch/read
  remote_config_object.dart                   # refactored: calls adaptor getters
```

### Base Adaptor Interface

```dart
abstract class BaseRemoteConfigAdaptor {
  Future<void> initialize(Map<String, dynamic> defaults);
  String getString(String key, String defaultValue);
  bool getBool(String key, bool defaultValue);
  int getInt(String key, int defaultValue);
  double getDouble(String key, double defaultValue);
  String getJsonString(String key, String defaultValue);
  Stream<Set<String>> get onConfigUpdated;

  static BaseRemoteConfigAdaptor? _instance;
  static BaseRemoteConfigAdaptor get instance { ... }
}
```

### Migration Steps

1. Create adaptor files
2. `RemoteConfigService.initialize()` → calls `adaptor.initialize(defaults)`
3. `_RemoteConfigObject.get()` → calls `adaptor.getString(key, defaultValue)` etc.
4. Remove direct `FirebaseRemoteConfig.instance` and `FirebaseCrashlytics.instance` usage from `remote_config_object.dart`

---

## 5. Cloud Storage (Firebase Storage → Adaptable CDN)

### Background

For Linux/FOSS, Firebase Storage is replaced by an alternative CDN (e.g. Netlify, Cloudinary). The **hash map** (`firestore_storage_map.json`) and **local caching logic** stay unchanged — only the download source changes.

### Key Design

- `CloudStorageService` (renamed from `CloudStorageService`) owns: hash map loading, path construction, caching, deduplication via `Completer`
- Adaptors implement only the **network-facing operations**: `downloadBytes(hashPath)` and `getDownloadUrl(hashPath)`
- The existing public API surface of `CloudStorageService` is preserved — callers don't change

### Files

```
lib/core/services/cloud_storage/                  # renamed from firestore_storage_service.dart
  adaptors/
    base_cloud_storage_adaptor.dart               # abstract: downloadBytes, getDownloadUrl
    firebase_cloud_storage_adaptor.dart           # uses firebase_storage SDK
    cdn_cloud_storage_adaptor.dart                # uses http.get() to a configurable base URL
  cloud_storage_service.dart                      # renamed CloudStorageService; uses adaptor
lib/core/initializers/
  cloud_storage_initializer.dart                  # renamed firestore_storage_initializer.dart
```

### Base Adaptor Interface

```dart
abstract class BaseCloudStorageAdaptor {
  // --- Only these 2 methods need implementation ---
  Future<Uint8List?> downloadBytes(String hashPath);
  Future<String?> getDownloadUrl(String hashPath);

  static BaseCloudStorageAdaptor? _instance;
  static BaseCloudStorageAdaptor get instance { ... }
}
```

### `CdnCloudStorageAdaptor`

```dart
class CdnCloudStorageAdaptor extends BaseCloudStorageAdaptor {
  final String baseUrl; // e.g. 'https://cdn.storypad.me'

  @override
  Future<Uint8List?> downloadBytes(String hashPath) async {
    final response = await http.get(Uri.parse('$baseUrl$hashPath'));
    if (response.statusCode == 200) return response.bodyBytes;
    return null;
  }

  @override
  Future<String?> getDownloadUrl(String hashPath) async =>
      '$baseUrl$hashPath';
}
```

The CDN base URL can be hardcoded or loaded from a dart define (`--dart-define=CDN_BASE_URL=https://cdn.storypad.me`).

### Migration Steps

1. Create `lib/core/services/cloud_storage/` directory with adaptor files
2. Move `CloudStorageService` → `CloudStorageService`, replace Firebase calls with `adaptor.downloadBytes()` and `adaptor.getDownloadUrl()`
3. Rename response/state types: `FirestoreStorageResponse` → `CloudStorageResponse`, `FirestoreStorageState` → `CloudStorageState`
4. Update all 17 callers to import `cloud_storage_service.dart`
5. Rename `firestore_storage_initializer.dart` → `cloud_storage_initializer.dart`

---

## 6. Google Drive — Linux Stub

### Key Design

`BackupCloudService` is already abstract. A new `GoogleDriveLinuxCloudService` extends it, returning failure/empty for all operations. Later it can be replaced with a real local-filesystem or alternative implementation.

### Files

```
lib/core/services/backups/
  google_drive_cloud_service.dart          # existing, unchanged
  google_drive_linux_cloud_service.dart    # NEW: stub
```

### Implementation Sketch

```dart
class GoogleDriveLinuxCloudService extends BackupCloudService {
  @override
  BackupServiceType get serviceType => BackupServiceType.google_drive;

  @override
  CloudServiceUser? get currentUser => null;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> signIn() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> requestScope() async => false;

  @override
  Future<bool> reauthenticateIfNeeded() async => false;

  @override
  Future<bool> canAccessRequestedScopes() async => false;

  @override
  void setAutoBackupEnabled(bool enabled) {}

  @override
  Future<Map<int, CloudFileObject>> fetchYearlyBackups() async => {};

  @override
  Future<(String, int)?> getFileContent(CloudFileObject file) async => null;

  @override
  Future<CloudFileObject?> uploadFile(String fileName, io.File file, {required String folderName}) async => null;
  // ... other required methods return null / false / empty
}
```

The `BackupProvider` selects the service:

```dart
BackupCloudService _createGoogleDriveService() {
  if (!kIsWeb && Platform.isLinux) return GoogleDriveLinuxCloudService();
  return GoogleDriveCloudService();
}
```

---

## Implementation Order (Suggested)

1. **Error Reporting** — smallest scope, unblocks Crashlytics removal from `remote_config_object.dart`
2. **Remote Config** — needed to remove Firebase dependency from community/onboarding views
3. **Analytics (Events + User Properties)** — independent, high call-site count but mechanical refactor
4. **Cloud Storage** — most callers; do after analytics is done so each PR is focused
5. **Google Drive Linux Stub** — independent, can be done anytime

## Progress

- [x] Error Reporting adaptor
- [x] Remote Config adaptor
- [x] Analytics Event adaptor
- [x] Analytics User Property adaptor
- [x] Cloud Storage adaptor
- [x] Google Drive Linux stub
