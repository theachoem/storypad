# StoryPad - Open Source Diary & Journal App

StoryPad is a Flutter mobile application with multiple flavors (community, storypad, spooky) available for iOS and Android. It's a privacy-first journal app with timeline-based entries, photo support, mood tracking, and comprehensive customization options.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

**IMPORTANT**: These instructions have been created based on repository analysis and documentation review. Full testing was limited by network restrictions that prevented Flutter SDK installation and dependency downloads. All commands and timings are based on standard Flutter project patterns and the specific project structure observed.

### Prerequisites
Install the exact tool versions specified in `.tool-versions`:
- Java: 21 (LTS) - for Android builds (current system has Java 17, upgrade required)
- Ruby: 3.3.5 - for iOS/CocoaPods management  
- Flutter: 3.35.1-stable

**CRITICAL**: The system currently has Java 17 but the project requires Java 21. This will cause build failures. Install Java 21 before proceeding.

**If using asdf** (recommended), follow the detailed setup guide in `docs/setup_asdf.md`:
```sh
asdf plugin add java
asdf install java openjdk-21
asdf plugin add ruby  
asdf install ruby 3.3.5
asdf plugin add flutter
asdf install flutter 3.35.1-stable
```

**Manual installation**: Install the above versions using fvm, rvm, rbenv, or direct downloads. Ensure they are in PATH and properly configured.

### Bootstrap the Repository
Run these commands in order to set up the development environment:

```sh
# 1. Get dependencies
flutter pub get
# NEVER CANCEL: Takes 2-5 minutes depending on network. Set timeout to 10+ minutes.

# 2. Generate code (required for build)
dart run build_runner build
# NEVER CANCEL: Takes 1-3 minutes. Set timeout to 5+ minutes.

# 3. Verify setup
flutter doctor
# Should show no critical issues for your target platform
```

### Development Workflow

#### Run the Application
Use the convenience script for different flavors:

```sh
# Community flavor (default/open source)
bin/dev --community

# Alternative direct command:
flutter run --flavor community --dart-define-from-file=configs/community.json --target=lib/main_community.dart

# iOS with Cupertino design
bin/dev --community-ios

# Other flavors (for maintainers)
bin/dev --storypad
bin/dev --spooky
```

**NEVER CANCEL: Initial run takes 10-15 minutes for cold build. Set timeout to 20+ minutes.**
Hot reload after initial build is instant.

#### Build for Release

```sh
# Android APK
bin/build_apk --community
# NEVER CANCEL: Takes 15-25 minutes. Set timeout to 30+ minutes.

# Android App Bundle (for Play Store)
bin/build_appbundle --community  
# NEVER CANCEL: Takes 15-25 minutes. Set timeout to 30+ minutes.

# iOS (requires macOS)
bin/build_ipa --community
# NEVER CANCEL: Takes 20-30 minutes. Set timeout to 40+ minutes.
```

### Testing

```sh
# Run all tests
flutter test
# NEVER CANCEL: Takes 2-5 minutes with 17 test files. Set timeout to 10+ minutes.

# Run specific test file
flutter test test/core/services/minimum_execution_time_service_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality

```sh
# Analyze code (linting)
flutter analyze
# Takes 30-60 seconds. Shows warnings/errors from analysis_options.yaml

# Format code
dart format .
# Auto-formats all Dart files according to Dart style guide

# Check for outdated packages
bin/pubspec/outdated
```

## Validation

Always manually validate changes using these complete scenarios:

### Basic Development Validation
1. **Setup validation**: Run `flutter doctor` - should show no critical issues
2. **Project structure validation**: 
   ```sh
   # Verify key files exist
   ls lib/main_community.dart configs/community.json translations/en.json
   # Should show all three files without errors
   ```
3. **Dependencies validation**: Run `flutter pub get` - should complete without errors
4. **Code generation validation**: Run `dart run build_runner build` - should complete successfully
5. **Build validation**: Run `bin/dev --community` - app should start without errors  
6. **Hot reload test**: Make a small UI change, save file - should hot reload instantly
7. **Test validation**: Run `flutter test` - all tests should pass

### Manual Testing Scenarios  
After making changes, always test these core workflows:

1. **App Launch**: Open app, verify splash screen and main timeline view loads
2. **Create Entry**: Tap "+" button, create a new journal entry with text
3. **Photo Support**: Add a photo to an entry (if UI change affects media)
4. **Navigation**: Navigate between different screens (timeline, settings, etc.)
5. **Flavor Testing**: If changing configs, test with `bin/dev --community` to ensure proper flavor loading

### Build System Validation
Before committing changes that affect build:
```sh
# 1. Verify project structure
ls lib/main_community.dart configs/community.json translations/en.json
# All files should exist

# 2. Clean build
flutter clean && flutter pub get
# NEVER CANCEL: Takes 2-5 minutes. Set timeout to 10+ minutes.

# 3. Code generation  
dart run build_runner build --delete-conflicting-outputs
# NEVER CANCEL: Takes 1-3 minutes. Set timeout to 5+ minutes.

# 4. Full build test
bin/build_apk --community
# NEVER CANCEL: Takes 15-25 minutes. Set timeout to 30+ minutes.
```

## Key Project Structure

### Important Directories
- `lib/` - Main application code with MVVM architecture
- `lib/core/` - Shared utilities, services, and base classes
- `lib/views/` - UI screens and view logic
- `lib/providers/` - State management providers
- `configs/` - Flavor-specific configuration files
- `bin/` - Development and build scripts
- `test/` - Unit and widget tests
- `translations/` - Localization files (20+ languages)

### Development Scripts (bin/)
- `bin/dev` - Run app with specific flavor
- `bin/build_apk` - Build Android APK
- `bin/build_appbundle` - Build Android App Bundle
- `bin/build_ipa` - Build iOS app
- `bin/build_runner` - Generate code
- `bin/localize` - Update translations

### State Management
StoryPad uses a three-tier state management approach:
- **Global State**: Provider-based, managed in `provider_scope.dart`
- **View State**: ViewModelProvider for screen-specific state  
- **Widget State**: StatefulWidget for component-level state

### Database
Uses ObjectBox for local storage with model definitions in `lib/core/` and generated code via build_runner.

## Common Issues & Solutions

### Network Requirements
StoryPad requires internet access for:
- Initial Flutter setup and dependency downloads
- Pub package installation (`flutter pub get`)
- Firebase services and analytics
- Google Drive sync functionality

If you encounter network-related errors:
- Ensure internet connectivity is available
- Check if corporate firewalls are blocking Flutter/Dart package repositories
- Verify DNS resolution is working properly

### Build Failures
- **"ObjectBox not found"**: Run `dart run build_runner build`
- **"Flutter doctor issues"**: Install missing platform tools (Android Studio, Xcode)
- **"Gradle errors"**: Check Java version is exactly 21
- **"CocoaPods errors"**: Run `cd ios && pod install` or update Ruby version

### Development Issues  
- **Hot reload not working**: Run `flutter clean` then restart
- **Localization errors**: Ensure `translations/en.json` exists and is valid
- **Flavor config errors**: Verify `configs/*.json` files exist and contain valid JSON

### Performance
- **Slow builds**: Increase heap size: `export JAVA_OPTS="-Xmx4g"`
- **Slow startup**: First run always slow, subsequent runs faster with hot reload

## References

### Key Files to Check
- `pubspec.yaml` - Dependencies and Flutter version constraints
- `analysis_options.yaml` - Linting rules and code style
- `.tool-versions` - Required tool versions
- `docs/setup_asdf.md` - Detailed environment setup
- `CONTRIBUTING.md` - Contribution guidelines and workflow

### External Resources
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Documentation](https://docs.flutter.dev/)
- [ObjectBox Flutter](https://docs.objectbox.io/flutter/)

## Quick Command Reference

```sh
# Setup
flutter pub get && dart run build_runner build

# Development  
bin/dev --community

# Testing
flutter test
flutter analyze

# Building
bin/build_apk --community
bin/build_appbundle --community

# Maintenance
flutter clean
dart format .
```

Always set appropriate timeouts (10+ minutes for builds, 5+ minutes for tests) and NEVER CANCEL long-running operations as they are normal for Flutter projects.