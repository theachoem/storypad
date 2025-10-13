# Creating Features

**Step-by-step guide for creating new features.**

## 1. Plan Structure

```
views/[feature]/
├── [feature]_view.dart              # List page
├── show/show_[feature]_view.dart    # Detail page
├── edit/edit_[feature]_view.dart    # Edit page
└── local_widgets/                    # Feature widgets
```

## 2. Create View

```dart
class EditStoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditStoryViewModel(),
      child: EditStoryContent(),
    );
  }
}
```

## 3. Create ViewModel

```dart
class EditStoryViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> save() async {
    _isLoading = true;
    notifyListeners();

    // Business logic here

    _isLoading = false;
    notifyListeners();
  }
}
```

## 4. Create ViewContent

```dart
class EditStoryContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EditStoryViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Edit Story')),
      body: viewModel.isLoading
        ? CircularProgressIndicator()
        : YourUI(),
    );
  }
}
```

## State Management Levels

| Level  | Scope  | Lifecycle       | Example              |
| ------ | ------ | --------------- | -------------------- |
| App    | Global | App lifetime    | `ThemeProvider`      |
| View   | Screen | Screen lifetime | `EditStoryViewModel` |
| Widget | Local  | Widget lifetime | `StatefulWidget`     |

## Quick Checklist

- [ ] Create feature folder in `views/`
- [ ] Follow MVVM pattern (View, ViewModel, ViewContent)
- [ ] Use `SpIcons` for icons
- [ ] Use `adaptive_dialog` for dialogs
- [ ] Add to routing if needed
- [ ] Write tests for ViewModel
- [ ] Test on both iOS and Android
- [ ] Update documentation if needed

## See Also

- [Architecture](../core/architecture.md) - MVVM pattern details
- [File Organization](../core/file-organization.md) - Project structure
- [Code Patterns](code-patterns.md) - Common code snippets
