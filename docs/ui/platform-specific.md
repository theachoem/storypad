# Platform-Specific UI

**Use platform checks for different behaviors between iOS and Android.**

## Adaptive Widgets

```dart
import 'package:storypad/core/constants/app_constants.dart';

if (kIsCupertino) {
  // iOS-specific UI
  return CupertinoButton(...);
} else {
  // Android-specific UI
  return ElevatedButton(...);
}
```

## Common Patterns

### Dialogs

```dart
// Use adaptive_dialog package (see ../development/dependencies.md)
import 'package:adaptive_dialog/adaptive_dialog.dart';

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

### Navigation

```dart
// Use Flutter Navigator 1.0
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => MyView()),
);

// Pop with result
Navigator.of(context).pop(result);
```

## Platform Check Constant

```dart
// core/constants/app_constants.dart
import 'dart:io';

const bool kIsCupertino = Platform.isIOS || Platform.isMacOS;
```

## See Also

- [Icons](icons.md) - Platform-adaptive icons with SpIcons
- [Common Components](common-components.md) - Adaptive UI components
