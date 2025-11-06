# iOS Configuration

**iOS-specific configuration and setup.**

## Info.plist

Location: `ios/Runner/Info.plist`

### File Picker

Required by `file_picker` package for document browsing.

```xml
<key>UISupportsDocumentBrowser</key>
<true/>

<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

**Reference**: [file_picker setup](https://github.com/miguelpruivo/flutter_file_picker/wiki/Setup)

### Background Audio

Required by `audio_service` for relax sounds playback.

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

**Reference**: [audio_service](https://pub.dev/packages/audio_service)

## Runner.entitlements

Location: `ios/Runner/Runner.entitlements`

### Keychain Sharing

Required by `flutter_secure_storage` for secure credential storage.

**How to add:**

1. Open `Runner.xcworkspace` in Xcode
2. Select Target > Runner > Signing & Capabilities
3. Click "+ Capability"
4. Add "Keychain Sharing"

**Generated content:**

```xml
<dict>
  <key>keychain-access-groups</key>
  <array />
</dict>
```

**Reference**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)

## Signing Configuration

Location: `ios/Runner.xcodeproj/`

**Setup in Xcode:**

- Signing & Capabilities
- Provisioning profiles
- Certificates

## Build Commands

```bash
# Development
flutter run --flavor community --dart-define-from-file=configs/community.json --target=lib/main_community.dart

# Release
flutter build ios --flavor storypad --dart-define-from-file=configs/storypad.json --target=lib/main_storypad.dart
```

## Common Issues

### Build Fails

- Check Xcode version compatibility
- Verify provisioning profiles
- Clean build: `flutter clean && flutter pub get`

### Signing Issues

- Verify certificates are valid
- Check provisioning profile matches bundle ID
- Ensure correct team selected

## See Also

- [Android Config](android-config.md) - Android-specific configuration
- [Platform-Specific UI](../ui/platform-specific.md) - Platform-adaptive code
