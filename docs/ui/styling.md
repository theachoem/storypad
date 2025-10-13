# Styling

**Theme usage and responsive design patterns.**

## Theme Usage

### Accessing Theme

```dart
// Access theme
final theme = Theme.of(context);
final textTheme = theme.textTheme;
final colorScheme = theme.colorScheme;

// Use theme colors
color: theme.primaryColor,
backgroundColor: colorScheme.surface,
```

### Text Styles

```dart
// Use theme text styles
Text(
  'Title',
  style: textTheme.titleLarge,
)

Text(
  'Body',
  style: textTheme.bodyMedium,
)

Text(
  'Caption',
  style: textTheme.bodySmall,
)
```

### Colors

```dart
// Use color scheme
final colorScheme = Theme.of(context).colorScheme;

Container(
  color: colorScheme.primary,
  child: Text(
    'Text',
    style: TextStyle(color: colorScheme.onPrimary),
  ),
)
```

## Responsive Design

### MediaQuery

```dart
// Get screen size
final size = MediaQuery.of(context).size;
final width = size.width;
final height = size.height;

// Check device type
final isTablet = width > 600;
final isPhone = width <= 600;

// Responsive layout
if (isTablet) {
  return TabletLayout();
} else {
  return PhoneLayout();
}
```

### Responsive Padding

```dart
// Adaptive padding based on screen size
final padding = width > 600 ? 24.0 : 16.0;

Padding(
  padding: EdgeInsets.all(padding),
  child: child,
)
```

### Orientation

```dart
final orientation = MediaQuery.of(context).orientation;

if (orientation == Orientation.landscape) {
  return LandscapeLayout();
} else {
  return PortraitLayout();
}
```

## Custom Styling

### Constants

Define reusable constants in feature or app-level:

```dart
// Feature-level constants
class StoryConstants {
  static const double cardBorderRadius = 12.0;
  static const double cardElevation = 2.0;
}

// Use in widgets
BorderRadius.circular(StoryConstants.cardBorderRadius)
```

### Avoid Hardcoding

```dart
// ❌ Don't
color: Color(0xFF123456)
fontSize: 16.0

// ✅ Do
color: theme.primaryColor
style: textTheme.bodyMedium
```

## See Also

- [Common Components](common-components.md) - Styled UI components
- [Platform-Specific](platform-specific.md) - Platform-adaptive UI
