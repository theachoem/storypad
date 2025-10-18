# Templates Add-on

**Price:** $0.99 (one-time purchase)

## Description

Create your own daily writing templates. The Templates add-on allows you to design reusable writing structures that help you maintain consistency and establish productive writing habits.

## Screenshots

|                                                                                  |                                                                                  |                                                                                  |                                                                                  |
| :------------------------------------------------------------------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------------------------------: | :------------------------------------------------------------------------------: |
| ![Screenshot 1](../../firestore_storages/add_ons_demos/templates/template_1.jpg) | ![Screenshot 2](../../firestore_storages/add_ons_demos/templates/template_2.jpg) | ![Screenshot 3](../../firestore_storages/add_ons_demos/templates/template_3.jpg) | ![Screenshot 4](../../firestore_storages/add_ons_demos/templates/template_4.jpg) |

## Features

### Template Creation

- **Custom Content:** Design your template with any text, formatting, or structure
- **Rich Text Support:** Use all story editor features (markdown, formatting, etc.)
- **Tag Support:** Organize templates with tags
- **Preferences:** Each template can have its own visual preferences

### Template Management

- **Create:** Design new templates from scratch
- **Edit:** Modify existing templates anytime
- **Archive:** Archive templates you're not currently using
- **Reorder:** Drag and drop to organize your template list
- **Delete:** Remove templates you no longer need

### Template Usage

- **Quick Access:** View all templates in one place
- **Preview:** See template content before using
- **Apply:** Use a template to create a new story with pre-filled content
- **Date Context:** Templates can be applied to specific dates

## Use Cases

### Daily Journaling

Create a template with prompts like:

- What am I grateful for today?
- What did I accomplish?
- What challenges did I face?
- What's my plan for tomorrow?

### Writing Practice

Structure your practice sessions:

- Warm-up exercise
- Main writing prompt
- Reflection section

### Goal Tracking

Monitor progress consistently:

- Today's goals
- Progress update
- Obstacles encountered
- Next steps

### Creative Writing

Maintain story structure:

- Scene setting
- Character development
- Plot points
- Dialogue notes

## Technical Implementation

### Core Files

```
lib/
├── core/
│   └── databases/
│       └── models/
│           ├── template_db_model.dart
│           ├── story_content_db_model.dart
│           └── story_preferences_db_model.dart
└── views/
    └── templates/
        ├── templates_view.dart
        ├── templates_view_model.dart
        ├── templates_content.dart
        ├── edit/
        │   ├── edit_template_view.dart
        │   └── edit_template_view_model.dart
        ├── show/
        │   ├── show_template_view.dart
        │   └── show_template_view_model.dart
        └── local_widgets/
            ├── template_tile.dart
            ├── template_tag_labels.dart
            └── empty_body.dart
```

### Key Components

**TemplatesViewModel** (`lib/views/templates/templates_view_model.dart`)

- Loads templates from database
- Handles navigation to create/edit/show views
- Manages template reordering
- Filters archived vs active templates

**TemplateDbModel** (`lib/core/databases/models/template_db_model.dart`)

- Core template data structure
- Properties:
  - `id`: Unique identifier
  - `index`: Sort order
  - `tags`: Associated tag IDs
  - `content`: Template content (StoryContentDbModel)
  - `preferences`: Visual preferences (StoryPreferencesDbModel)
  - `createdAt`, `updatedAt`: Timestamps
  - `archivedAt`: Archive status
  - `lastSavedDeviceId`: Sync tracking
  - `storiesCount`: Usage tracking

### Database

**Storage:** ObjectBox local database

- Adapter: `TemplatesBox` (`lib/core/databases/adapters/objectbox/templates_box.dart`)
- Supports filtering by archived status
- Maintains sort order via `index` field

### Template Structure

Templates reuse the same content and preferences models as stories:

**StoryContentDbModel**

- Stores the actual template text and formatting
- Same structure as regular story content

**StoryPreferencesDbModel**

- Visual settings (font, colors, etc.)
- Applied when creating stories from template

### Demo Assets

Template screenshots for the add-on showcase:

- Path: `/add_ons_demos/templates/`
- Files: `1.png`, `2.png`, `3.png`, `4.png`

### Translations

UI text is localized:

- Add-on metadata: `add_ons.templates.title`, `add_ons.templates.subtitle`
- Page title: `page.templates.title`
- Empty state: `page.templates.empty_message`
- Buttons: `button.new_template`, `button.use_template`

## User Flow

### Creating a Template

1. Navigate to Add-ons → Templates
2. Tap "New Template" button
3. Design your template content
4. Add tags (optional)
5. Set preferences (optional)
6. Save the template

### Using a Template

1. Browse your template library
2. Tap on a template to preview
3. Tap "Use this template"
4. Template content is copied to a new story
5. Edit and customize as needed
6. Save as a regular story

### Managing Templates

1. **Reorder:** Long-press and drag templates
2. **Edit:** Tap template → Edit
3. **Archive:** Move unused templates to archives
4. **View Archives:** Access archived templates separately
5. **Delete:** Permanently remove templates

## Purchase Verification

The add-on checks purchase status via:

- `InAppPurchaseProvider.template` getter
- Product identifier: `AppProduct.templates`
- Supports both purchased and reward-unlocked access

## Integration with Stories

When a template is used:

1. Template content is copied to a new story
2. Template preferences are applied
3. Template tags can be inherited
4. Story is created with current date (or specified date)
5. Original template remains unchanged
6. Template usage count can be tracked
