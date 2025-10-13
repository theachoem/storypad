# Platform Patterns

**Platform-adaptive code patterns and build configuration.**

## Checking Platform

```dart
import 'package:storypad/core/constants/app_constants.dart';

if (kIsCupertino) {
  // iOS-specific code
} else {
  // Android-specific code
}
```

## Adaptive Icons

```dart
import 'package:storypad/widgets/sp_icons.dart';

// Automatically adapts to platform
Icon(SpIcons.edit)
Icon(SpIcons.delete)
Icon(SpIcons.save)
```

See [UI Icons](../ui/icons.md) for full SpIcons documentation.

## Adaptive Dialogs

```dart
import 'package:adaptive_dialog/adaptive_dialog.dart';

// Automatically uses Cupertino or Material style
await showOkAlertDialog(
  context: context,
  title: 'Title',
  message: 'Message',
);

await showOkCancelAlertDialog(
  context: context,
  title: 'Confirm',
  message: 'Are you sure?',
);
```

## Adaptive Widgets

```dart
import 'package:storypad/core/constants/app_constants.dart';

Widget buildButton() {
  if (kIsCupertino) {
    return CupertinoButton(
      onPressed: onPressed,
      child: Text('Button'),
    );
  } else {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text('Button'),
    );
  }
}
```

## Platform Channels

**Current Status**: Not implemented yet.

**Future Considerations**:

- Evaluate need before implementing
- Document in this file when added
- Consider platform-specific limitations

## Build Commands

### iOS

```bash
# Development
flutter run --flavor community --dart-define-from-file=configs/community.json --target=lib/main_community.dart

# Release
flutter build ios --flavor storypad --dart-define-from-file=configs/storypad.json --target=lib/main_storypad.dart
```

### Android

```bash
# Development
flutter run --flavor community --dart-define-from-file=configs/community.json --target=lib/main_community.dart

# Release
flutter build appbundle --flavor storypad --dart-define-from-file=configs/storypad.json --target=lib/main_storypad.dart
```

## Flavors

The app has 3 flavors:

- **community** → Community version
- **spooky** → Spooky version
- **storypad** → StoryPad version (main)

Each flavor has:

- Unique application ID
- Separate Firebase configuration
- Flavor-specific configs in `configs/`

## Platform-Specific Dependencies

Some packages require platform-specific setup:

- Always check package documentation
- Test on both platforms before release
- Document platform requirements

## Testing on Both Platforms

```bash
# Test on iOS simulator
flutter run --flavor community --target=lib/main_community.dart

# Test on Android emulator
flutter run --flavor community --target=lib/main_community.dart

# Run tests
flutter test
```

## Common Issues

### Platform-Specific Bugs

- Test thoroughly on both platforms
- Check platform-specific APIs
- Verify adaptive widgets work correctly

### Build Issues

- See [iOS Config](ios-config.md) for iOS issues
- See [Android Config](android-config.md) for Android issues

## See Also

- [iOS Config](ios-config.md) - iOS-specific configuration
- [Android Config](android-config.md) - Android-specific configuration
- [UI Platform-Specific](../ui/platform-specific.md) - UI patterns
- [Commands](../guides/commands.md) - Build commands
