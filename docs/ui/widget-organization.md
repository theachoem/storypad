# Widget Organization

**Guidelines for organizing widgets in the codebase.**

## Reusable vs Local Widgets

### Reusable Widgets → `lib/widgets/`

- Used across multiple features
- Generic, configurable
- Example: `SpIcons`, `BaseView`, bottom sheets

**When to create reusable widget:**

- Used in 3+ different features
- Generic enough to be configured
- No tight coupling to specific feature logic

### Local Widgets → `lib/views/[feature]/local_widgets/`

- Feature-specific
- Tightly coupled to feature logic
- Example: `StoryToolbar`, `TagPicker`

**When to create local widget:**

- Only used within one feature
- Depends on feature-specific ViewModel
- Simplifies feature's main view file

## Widget State Rules

### When to use StatefulWidget

- Widget needs local UI state (e.g., animation, form input)
- State doesn't belong in ViewModel
- State is disposed when widget removed

**Example:**

```dart
class AnimatedButton extends StatefulWidget {
  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### When to use StatelessWidget

- Widget is pure UI
- Consumes data from ViewModel/Provider
- No local state needed

**Example:**

```dart
class StoryCard extends StatelessWidget {
  final Story story;

  const StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text(story.title),
    );
  }
}
```

## Widget Extraction

**Extract widgets when:**

- View file exceeds ~200 lines
- Widget is reused within the feature
- Widget has complex logic that can be isolated

**Don't extract when:**

- Widget is just a few lines
- Extraction reduces readability
- Widget is used only once and simple

## See Also

- [Architecture](../architecture/architecture.md) - MVVM pattern and state management
- [File Organization](../architecture/file-organization.md) - Project structure
