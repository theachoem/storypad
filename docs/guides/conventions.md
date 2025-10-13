# Conventions

**File locations and naming conventions.**

## File Locations

| What             | Where                            |
| ---------------- | -------------------------------- |
| Database models  | `core/databases/`                |
| Services         | `core/services/`                 |
| Repositories     | `core/repositories/`             |
| Storage          | `core/storages/`                 |
| Constants        | `core/constants/`                |
| Utils            | `core/utils/`                    |
| Extensions       | `core/extensions/`               |
| Global providers | `providers/`                     |
| Feature screens  | `views/[feature]/`               |
| Reusable widgets | `widgets/`                       |
| Feature widgets  | `views/[feature]/local_widgets/` |
| Icons            | `widgets/sp_icons.dart`          |

## Naming Conventions

### Files

- `edit_story_view.dart`
- `edit_story_view_model.dart`
- `edit_story_content.dart`
- `story_db_model.dart`
- `story_repository.dart`
- `story_service.dart`

**Rules:**

- Use `snake_case` for file names
- Suffix with type: `_view`, `_view_model`, `_content`, `_repository`, `_service`
- Match class name but in snake_case

### Classes

- `EditStoryView`
- `EditStoryViewModel`
- `EditStoryContent`
- `StoryDbModel`
- `StoryRepository`
- `StoryService`

**Rules:**

- Use `PascalCase` for class names
- Suffix with type: `View`, `ViewModel`, `Content`, `Repository`, `Service`
- Descriptive and specific names

### Variables

```dart
// Use camelCase
final userName = 'John';
final isLoading = false;
final itemCount = 10;

// Private variables start with _
final _privateValue = 'secret';

// Constants use lowerCamelCase
const maxRetries = 3;

// Static constants use lowerCamelCase
static const defaultTimeout = Duration(seconds: 30);
```

### Functions

```dart
// Use camelCase
void saveData() {}
Future<void> loadItems() async {}
bool isValid() => true;

// Private functions start with _
void _helperFunction() {}
```

## Import Order

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// 3. Package imports
import 'package:provider/provider.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

// 4. Project imports
import 'package:storypad/core/constants/constants.dart';
import 'package:storypad/widgets/sp_icons.dart';
```

## Code Style

### Use const constructors

```dart
// ✅ Good
const Text('Hello')
const SizedBox(height: 16)
const Icon(SpIcons.edit)

// ❌ Avoid
Text('Hello')
SizedBox(height: 16)
Icon(SpIcons.edit)
```

### Extract magic numbers

```dart
// ❌ Avoid
Padding(padding: EdgeInsets.all(16))
BorderRadius.circular(8)

// ✅ Good
class AppConstants {
  static const double paddingDefault = 16.0;
  static const double borderRadiusDefault = 8.0;
}

Padding(padding: EdgeInsets.all(AppConstants.paddingDefault))
BorderRadius.circular(AppConstants.borderRadiusDefault)
```

### Keep functions small

```dart
// ✅ Good - Single responsibility
void saveStory() {
  _validateStory();
  _persistToDatabase();
  _notifyListeners();
}

// ❌ Avoid - Too many responsibilities
void saveStory() {
  // 100+ lines of mixed logic
}
```

## See Also

- [File Organization](../core/file-organization.md) - Project structure
- [Architecture](../core/architecture.md) - MVVM pattern
