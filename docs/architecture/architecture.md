# Architecture

## State Management

StoryPad uses **Provider + ChangeNotifier** with 3-level state hierarchy:

### 1. App State (Global)

- **Scope**: ProviderScope (`lib/provider_scope.dart`)
- **Lifecycle**: Disposed when app closes
- **Usage**: Theme, auth, app-wide settings
- **Example**: `ThemeProvider`, `BackupProvider`

### 2. View State

- **Scope**: ViewModelProvider (`lib/widgets/base_view/view_model_provider.dart`)
- **Lifecycle**: Disposed when page closes
- **Usage**: Screen-specific business logic
- **Pattern**: Each screen has its own ViewModel (ChangeNotifier)
- **Example**: `EditStoryViewModel`, `ShowStoryViewModel`

### 3. Widget State

- **Scope**: StatefulWidget
- **Lifecycle**: Disposed when widget removed from tree
- **Usage**: Local widget state only
- **Rule**: Avoid excessive state in ViewModel—keep only necessary state there

## MVVM Pattern

StoryPad follows **MVVM** with 3-4 files per feature:

```
views/stories/edit/
├── edit_story_view.dart          # Constructs ViewModel, builds UI
├── edit_story_content.dart       # Renders UI (visual only)
├── edit_story_view_model.dart    # Business logic, state management
└── local_widgets/                # Feature-specific widgets
```

### Component Roles

**Model** (Data Layer)

- `DbModel` → core/databases/
- `LocalStorage` → core/storages/
- `Repository` → core/repositories/
- `Service` → core/services/

**View**

- Constructs ViewModel via `ChangeNotifierProvider`
- Passes ViewModel to ViewContent
- Handles navigation

**ViewContent**

- Pure UI rendering
- No business logic
- Consumes ViewModel data

**ViewModel**

- Business logic
- State management
- Data operations
- Extends `ChangeNotifier`

## Routing Pattern

Follow Rails-style naming:

| Rails   | StoryPad        | Purpose     |
| ------- | --------------- | ----------- |
| `index` | `StoriesView`   | List page   |
| `show`  | `ShowStoryView` | Detail page |
| `new`   | `NewStoryView`  | Create page |
| `edit`  | `EditStoryView` | Edit page   |

**Navigation**: Uses Flutter Navigator 1.0 (not 2.0)

## Anti-Patterns to Avoid

❌ **Don't** put excessive state in ViewModel  
✅ **Do** keep only necessary state in ViewModel, use widget state for local UI

❌ **Don't** mix business logic in ViewContent  
✅ **Do** keep ViewContent pure UI, logic in ViewModel

❌ **Don't** use global state for screen-specific data  
✅ **Do** use appropriate state level (app/view/widget)

❌ **Don't** create all 4 MVVM files if not needed  
✅ **Do** adapt pattern to feature complexity (simple features may skip ViewModel)
