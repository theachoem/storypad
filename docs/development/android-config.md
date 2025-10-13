# Android Configuration

**Android-specific configuration and setup.**

## build.gradle (app-level)

Location: `android/app/build.gradle`

### Flavor Configuration

```gradle
flavorDimensions "default"
productFlavors {
    community {
        dimension "default"
        applicationId "com.tc.writestory.community"
    }
    storypad {
        dimension "default"
        applicationId "com.tc.writestory"
    }
    spooky {
        dimension "default"
        applicationId "com.tc.spooky"
    }
}
```

## Firebase Configuration

Location: `android/app/src/[flavor]/google-services.json`

Flavors:

- `community/` → Community version
- `spooky/` → Spooky version
- `storypad/` → StoryPad version

**Setup**: Download from Firebase Console for each flavor.

## Android Resources

### Notification Icons

Location: `android/app/src/main/res/drawable-*/`

**Generator**: [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/icons-notification.html)

**Usage**: Relax sounds notifications (ic_music_note, ic_stop)

**Example URL**:

```
https://romannurik.github.io/AndroidAssetStudio/icons-notification.html
  #source.type=clipart
  &source.clipart=music_note
  &source.space.trim=0
  &source.space.pad=0
  &name=ic_relax_sound
```

### Adaptive Icons

**Rule**: All app icons must be adaptive for Android.

**Tools**:

- `flutter_launcher_icons` package
- Config: `configs/flutter_launcher_icons/`

## Signing Configuration

Location: `android/keys/[flavor]/`

**Files**:

- `key.properties` → Keystore configuration
- `*.jks` → Keystore files

**Setup**: See `android/app/build.gradle` for signing config.

## Build Commands

```bash
# Development
flutter run --flavor community --dart-define-from-file=configs/community.json --target=lib/main_community.dart

# Release
flutter build appbundle --flavor storypad --dart-define-from-file=configs/storypad.json --target=lib/main_storypad.dart
```

## Common Issues

### Build Fails

- Check Java version (21 LTS required)
- Verify signing configuration
- Check flavor-specific resources
- Clean build: `flutter clean && flutter pub get`

### Gradle Issues

- Update Gradle wrapper if needed
- Check `gradle.properties` settings
- Verify Android SDK installation

### Flavor Issues

- Ensure `google-services.json` exists for each flavor
- Check flavor-specific resources
- Verify applicationId matches Firebase

## See Also

- [iOS Config](ios-config.md) - iOS-specific configuration
- [Platform Patterns](platform-patterns.md) - Platform-adaptive code
- [Commands](../guides/commands.md) - Build commands
