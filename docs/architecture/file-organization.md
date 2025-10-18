# File Organization

## lib/ Structure

```
lib/
├── core/                    # Core business logic (Model layer)
│   ├── constants/          # App-wide constants
│   ├── databases/          # ObjectBox models (DbModel)
│   ├── exceptions/         # Custom exceptions
│   ├── extensions/         # Dart extensions
│   ├── helpers/            # Helper functions
│   ├── mixins/             # Reusable mixins
│   ├── objects/            # Data objects
│   ├── repositories/       # Data repositories
│   ├── services/           # Business services
│   ├── storages/           # Local storage (SharedPreferences, etc.)
│   ├── types/              # Type definitions
│   ├── utils/              # Utility functions
│   └── view_models/        # Shared ViewModels
├── views/                   # Feature screens (View layer)
│   ├── stories/            # Story feature
│   │   ├── edit/          # Edit story screen
│   │   ├── show/          # Show story screen
│   │   └── local_widgets/ # Story-specific widgets
│   ├── tags/               # Tags feature
│   ├── settings/           # Settings feature
│   └── ...                 # Other features
├── widgets/                 # Reusable widgets
│   ├── sp_icons.dart       # Platform-adaptive icons
│   ├── base_view/          # Base view components
│   ├── bottom_sheets/      # Reusable bottom sheets
│   └── ...                 # Other shared widgets
├── providers/               # Global providers (App state)
├── view_models/             # Feature-specific ViewModels
├── initializers/            # App initialization logic
├── gen/                     # Generated code
└── main_*.dart              # Entry points
```

## Feature Placement Rules

### Creating New Features

**1. Feature-based organization**

```
views/[feature_name]/
├── [feature_name]_view.dart              # List/index page
├── show/show_[feature_name]_view.dart    # Detail page
├── edit/edit_[feature_name]_view.dart    # Edit page
├── new/new_[feature_name]_view.dart      # Create page (if needed)
└── local_widgets/                         # Feature-specific widgets
```

**2. MVVM files per screen**

```
views/stories/edit/
├── edit_story_view.dart          # View
├── edit_story_content.dart       # ViewContent
├── edit_story_view_model.dart    # ViewModel
└── local_widgets/                # Screen-specific widgets
```

### When to Create Files

**Model Layer** (core/)

- `DbModel` → When persisting data (ObjectBox)
- `Repository` → When abstracting data sources
- `Service` → When implementing business logic
- `Storage` → When using local storage (SharedPreferences, etc.)

**View Layer** (views/)

- `*_view.dart` → Always (entry point)
- `*_content.dart` → When UI is complex
- `*_view_model.dart` → When business logic exists
- `local_widgets/` → When widgets are feature-specific

**Widget Layer** (widgets/)

- Create here when widget is **reusable across features**
- Keep in `local_widgets/` when **feature-specific**

## Naming Conventions

### Files

- Views: `[action]_[feature]_view.dart` (e.g., `edit_story_view.dart`)
- ViewModels: `[action]_[feature]_view_model.dart`
- ViewContent: `[action]_[feature]_content.dart`
- Models: `[name]_db_model.dart`, `[name]_storage.dart`

### Classes

- Views: `EditStoryView extends StatelessWidget`
- ViewModels: `EditStoryViewModel extends ChangeNotifier`
- ViewContent: `EditStoryContent extends StatelessWidget`
- Models: `StoryDbModel`, `ThemeStorage`

## Examples from Codebase

**Story Feature** (full MVVM)

```
views/stories/
├── edit/
│   ├── edit_story_view.dart
│   ├── edit_story_content.dart
│   └── edit_story_view_model.dart
├── show/
│   ├── show_story_view.dart
│   ├── show_story_content.dart
│   └── show_story_view_model.dart
└── local_widgets/
    ├── story_toolbar.dart
    └── ...
```

**Settings Feature** (simpler structure)

```
views/settings/
└── settings_view.dart    # May not need ViewModel if simple
```

## Quick Reference

**Where to put...**

- Database models → `core/databases/`
- API services → `core/services/`
- Data repositories → `core/repositories/`
- Global providers → `providers/`
- Feature screens → `views/[feature]/`
- Reusable widgets → `widgets/`
- Feature widgets → `views/[feature]/local_widgets/`
- Constants → `core/constants/`
- Utilities → `core/utils/`
