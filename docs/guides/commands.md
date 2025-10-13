# Commands

**Flutter commands for development and deployment.**

## Run App

```bash
flutter run --flavor community --dart-define-from-file=configs/community.json --target=lib/main_community.dart
```

## Build

### Android

```bash
flutter build appbundle --flavor storypad --dart-define-from-file=configs/storypad.json --target=lib/main_storypad.dart
```

### iOS

```bash
flutter build ios --flavor storypad --dart-define-from-file=configs/storypad.json --target=lib/main_storypad.dart
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/path/to/test.dart

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Code Generation

```bash
# Generate code (ObjectBox, JSON, etc.)
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch

# Delete conflicting outputs
flutter pub run build_runner build --delete-conflicting-outputs
```

## Clean

```bash
flutter clean
flutter pub get
```

## Dependencies

```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Outdated packages
flutter pub outdated
```

## Analysis

```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Fix issues
dart fix --apply
```

## See Also

- [Testing](../development/testing-basics.md) - Testing patterns
- [Platform Config](../development/platform-patterns.md) - Build configuration
