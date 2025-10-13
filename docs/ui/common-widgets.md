# Common Widgets

**Frequently used UI widgets and patterns.**

## Bottom Sheets

```dart
// Show modal bottom sheet
showModalBottomSheet(
  context: context,
  builder: (_) => MyBottomSheet(),
);

// With custom properties
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => MyBottomSheet(),
);
```

**Location**: `lib/widgets/bottom_sheets/`

## Dialogs

```dart
// Use adaptive_dialog package
import 'package:adaptive_dialog/adaptive_dialog.dart';

// OK dialog
await showOkAlertDialog(
  context: context,
  title: 'Title',
  message: 'Message',
);

// OK/Cancel dialog
final result = await showOkCancelAlertDialog(
  context: context,
  title: 'Confirm',
  message: 'Are you sure?',
);

if (result == OkCancelResult.ok) {
  // User confirmed
}

// Text input dialog
final text = await showTextInputDialog(
  context: context,
  title: 'Enter text',
  textFields: [
    DialogTextField(hintText: 'Hint'),
  ],
);
```

See [dependencies.md](../development/dependencies.md) for `adaptive_dialog` package.

## Lists

### ListView.builder

```dart
// Use for performance with large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(
      title: Text(item.title),
      onTap: () => handleTap(item),
    );
  },
);
```

### ListView.separated

```dart
// With separators
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (context, index) => Divider(),
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index].title));
  },
);
```

### GridView

```dart
// Grid layout
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return GridTile(child: ItemCard(items[index]));
  },
);
```

## Loading Indicators

```dart
// Circular progress
Center(
  child: CircularProgressIndicator(),
)

// Platform-adaptive
if (kIsCupertino) {
  CupertinoActivityIndicator()
} else {
  CircularProgressIndicator()
}
```

## Empty States

```dart
// Empty state widget
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(SpIcons.empty, size: 64),
      SizedBox(height: 16),
      Text('No items found'),
    ],
  ),
)
```

## Buttons

```dart
// Elevated button
ElevatedButton(
  onPressed: () {},
  child: Text('Button'),
)

// Text button
TextButton(
  onPressed: () {},
  child: Text('Button'),
)

// Icon button
IconButton(
  icon: Icon(SpIcons.edit),
  onPressed: () {},
)
```

## See Also

- [Icons](icons.md) - Use SpIcons for all icons
- [Platform-Specific](platform-specific.md) - Adaptive dialogs and navigation
- [Styling](styling.md) - Theme and responsive design
