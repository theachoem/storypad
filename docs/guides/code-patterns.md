# Code Patterns

**Common code snippets and patterns.**

## Navigation

```dart
// Push
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => MyView()),
);

// Push replacement
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => MyView()),
);

// Pop
Navigator.of(context).pop();

// Pop with result
Navigator.of(context).pop(result);
```

## Dialogs

```dart
import 'package:adaptive_dialog/adaptive_dialog.dart';

// OK dialog
await showOkAlertDialog(
  context: context,
  title: 'Success',
  message: 'Operation completed',
);

// OK/Cancel dialog
final result = await showOkCancelAlertDialog(
  context: context,
  title: 'Confirm',
  message: 'Are you sure?',
);
if (result == OkCancelResult.ok) {
  // Proceed
}

// Text input dialog
final text = await showTextInputDialog(
  context: context,
  title: 'Enter name',
  textFields: [DialogTextField(hintText: 'Name')],
);
```

## Bottom Sheets

```dart
showModalBottomSheet(
  context: context,
  builder: (_) => MyBottomSheet(),
);
```

## Provider Usage

```dart
// Watch (rebuilds on change)
final viewModel = context.watch<MyViewModel>();

// Read (no rebuild)
final viewModel = context.read<MyViewModel>();

// Select (rebuild only when specific value changes)
final value = context.select<MyViewModel, String>(
  (vm) => vm.specificValue,
);
```

## ObjectBox Queries

```dart
// Get all
final items = box.getAll();

// Get by ID
final item = box.get(id);

// Query with condition
final query = box.query(Item_.name.equals('value')).build();
final results = query.find();
query.close();

// Query with multiple conditions
final query = box.query(
  Item_.name.contains('search') & Item_.isActive.equals(true)
).build();

// Order by
final query = box.query()
  .order(Item_.createdAt, flags: Order.descending)
  .build();

// Save
box.put(item);

// Delete
box.remove(id);
```

## SharedPreferences

```dart
final prefs = await SharedPreferences.getInstance();

// Save
await prefs.setString('key', 'value');
await prefs.setInt('count', 42);
await prefs.setBool('flag', true);

// Read
final value = prefs.getString('key');
final count = prefs.getInt('count') ?? 0;
final flag = prefs.getBool('flag') ?? false;

// Remove
await prefs.remove('key');
```

## Theme Access

```dart
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;
final textTheme = theme.textTheme;

// Colors
color: colorScheme.primary,
color: colorScheme.secondary,
color: colorScheme.surface,

// Text styles
style: textTheme.headlineLarge,
style: textTheme.bodyMedium,
```

## Icons

```dart
// Always use SpIcons
Icon(SpIcons.edit)
Icon(SpIcons.delete)
Icon(SpIcons.save)

// Never use directly
Icon(Icons.edit)  // ❌
Icon(CupertinoIcons.pencil)  // ❌
```

## Platform Checks

```dart
import 'package:storypad/core/constants/app_constants.dart';

if (kIsCupertino) {
  // iOS
} else {
  // Android
}
```

## Error Handling

### Try-Catch

```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  print('Error: $e');
  print('Stack: $stackTrace');
  // Handle error
}
```

### Result Types (for Backup)

```dart
final result = await backupRepository.upload();

result.when(
  success: (data) {
    // Handle success
  },
  failure: (error) {
    // Handle failure
  },
  partialSuccess: (data, errors) {
    // Handle partial success
  },
);
```

## See Also

- [Creating Features](creating-features.md) - Feature creation workflow
- [UI Icons](../ui/icons.md) - SpIcons usage
- [UI Components](../ui/common-components.md) - UI patterns
