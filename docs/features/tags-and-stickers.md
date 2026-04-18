# Tags & Stickers

## Overview

Tags and Stickers provide a flexible labeling system for stories. **Tags** are text-based labels (e.g., "Personal", "Travel"), while **Stickers** are emoji-based labels organized into categories like Feeling and Activity.

This system replaces the legacy `feeling` field on stories. Instead of a single string-based feeling, stories now use emoji tags with category support.

## Architecture

### Data Model

- **`TagDbModel`** — A tag with `id`, `title`, `emoji`, and `categoryId`
  - `categoryId == null` → normal text tag
  - `categoryId != null` → sticker (emoji tag belonging to a category)
  - IDs are generated via `TagIdGeneratorService`:
    - Time-based IDs (`< cutoff`) for normal tags
    - Emoji-based deterministic IDs (`>= cutoff`) for sticker tags — same emoji always produces the same ID

- **`TagCategoryDbModel`** — A tag category with `id`, `title`, `multiSelect`
  - System categories have `id < 1000` (e.g., Feeling=1 single-select, Activity=2 multi-select)
  - `TagCategoryDbModel.systemCategories` — ordered list of all system categories
  - Each category can suggest default emoji stickers via `suggestTags()`

### Database Layer

- **`TagsBox`** — ObjectBox adapter for tags, supports `category_id` and `created_year` filters in `buildQuery`
- **`TagCategoriesBox`** — ObjectBox adapter for tag categories
  - `getSuggestTagsByCategory({selectedTagIds})` — Returns a map of categories to their tags (suggested in defined order, then selected non-suggested extras)

### Provider

- **`TagsProvider`** — ChangeNotifier that holds the current tag list and emoji lookup
  - `tags` — normal text tags (`categoryId == null`)
  - `emojiTags` — sticker tags (`categoryId != null`)
  - `emojiById` — `Map<int, String>` (tagId → emoji) derived from `emojiTags`; used by calendar and story export
  - `setAllTags(allTags)` — splits a combined tag list into `tags`/`emojiTags` and rebuilds `emojiById`
  - `createTag(title)` — Optimistic insert: adds to local list immediately, rolls back on failure
  - Listens to `TagDbModel` global listener (debounced)

### ID Generation (`TagIdGeneratorService`)

```
cutoff = 1 << 60  (~1.15e18)

Time IDs:  < cutoff  (microsecondsSinceEpoch)
Emoji IDs: >= cutoff (deterministic hash of emoji runes)
```

This guarantees no collision between normal tags and emoji sticker tags.

## UI

### Story Header (Sticker Display)

In `SpStoryLabels`, sticker emojis are displayed inline in the story header area. If no stickers are selected, an add-sticker button (reaction icon) is shown. Tapping any sticker or the add button opens the tag sheet.

### `SpStoryTagsBottomSheet`

A full-screen bottom sheet with two tabs:

1. **Stickers Tab** — Grid of emoji stickers organized by category (Feeling, Activity). Uses `getSuggestTagsByCategory()` to show suggestions (in defined order) then any selected non-suggested extras. Tapping a sticker toggles it and persists to DB.

2. **Tags Tab** — List of normal text tags (`categoryId == null`) with fuzzy search. Includes a "New Tag" button at the bottom.

### Tag Ordering

When saving tags to a story, `BaseStoryViewModel.setTags()` automatically reorders the tag IDs: emoji/sticker tags (sorted by `categoryId`) come first, followed by normal text tags. This keeps the sticker display in the story header consistent regardless of toggle order.

### Integration Points

- **Show Story Page** — Tags sheet is accessible from the story header sticker area
- **Edit Story Page** — Same access via story header
- **Story Tile** — Sticker emojis shown inline (read-only, no tap to open sheet)
- Both pages no longer use the end drawer for tags; the tag button was removed from the AppBar

## Migration

### Feeling → Sticker Migration

`StoriesBox.migrateFeelingToTags()` converts legacy `feeling` string values to emoji tags:

1. Queries all stories with non-null `feeling` field
2. Maps each feeling key to its emoji via `legacyFeelingToEmojiMap`
3. Creates a `TagDbModel.emoji()` for each and adds to the story's tags
4. Clears the `feeling` field
5. Persists all changes

## Key Files

| File                                                            | Purpose                                            |
| --------------------------------------------------------------- | -------------------------------------------------- |
| `lib/core/databases/models/tag_db_model.dart`                   | Tag data model                                     |
| `lib/core/databases/models/tag_category_db_model.dart`          | Tag category model with system categories          |
| `lib/core/services/tag_id_generator_service.dart`               | Time/emoji ID generation                           |
| `lib/core/databases/adapters/objectbox/tags_box.dart`           | Tag DB operations                                  |
| `lib/core/databases/adapters/objectbox/tag_categories_box.dart` | Category DB + `getSuggestTagsByCategory()`         |
| `lib/widgets/bottom_sheets/sp_story_tags_bottom_sheet.dart`     | Tags/Stickers bottom sheet UI                      |
| `lib/widgets/sp_story_labels.dart`                              | Inline sticker display in story header             |
| `lib/views/stories/local_widgets/story_header.dart`             | Passes `onToggleTags` to labels                    |
| `lib/views/stories/local_widgets/base_story_view_model.dart`    | `setTags()` with emoji-first reordering            |
| `lib/providers/tags_provider.dart`                              | `emojiById` map, `setAllTags()`, `createTag()` API |

## Translation Keys

- `general.stickers` — "Stickers" tab label
- `general.tag_category.feeling` — "Feeling" category name
- `general.tag_category.activity` — "Activity" category name
- `page.tags.title` — "Tags" tab label (existing)
- `page.new_tag.title` — "New Tag" button (existing)
