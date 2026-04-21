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

In `SpStoryLabels`, sticker emojis and text tags are displayed inline in the story header. Two separate floating popup buttons appear when editing:

- **Tag button** (shown first) — opens `SpFloatingTagPicker`
- **Sticker button** — opens `SpEmojiTagPicker`

If no stickers are selected, only a small add-sticker icon button is shown. Once at least one sticker is selected, it appears as a tappable inline emoji that opens the picker.

### `SpFloatingTagPicker`

An inline floating popup for managing text tags. Features:

- Fuzzy search with `Fuzzy<TagDbModel>` weighted on `title`
- Slidable list items (swipe to delete)
- Inline tag creation and edit sub-page (`_EditTagView`) using `SpNestedNavigation` for in-place navigation
- Story count per tag displayed in the list

### `SpEmojiTagPicker`

An inline floating popup (max 288×320) for managing sticker emoji tags. Features:

- Sections per category, each showing its preset emoji grid
- **`+` button** in each category section — pushes `_EmojiKeyboardPage` inside the same `SpNestedNavigation` container (no new overlay)
- **`_EmojiKeyboardPage`** — full `EmojiPicker` (from `emoji_picker_flutter`) with a back button; pops with the selected emoji string
- Single-select categories replace the previously selected sticker in that category; multi-select categories accumulate selections

#### Custom Emoji ("1 Emoji = 1 Tag") Rule

When a user picks any emoji via the keyboard:

1. `TagDbModel.emoji(emoji, categoryId: category.id)` is constructed — the ID is **deterministic** (`TagIdGeneratorService.emojiId`), so the same emoji always resolves to the same tag ID regardless of which category it was picked from.
2. If the tag already exists in DB (`tag.exist()`): it is reused as-is — **original `categoryId` is preserved**, no duplicate is created.
3. If it doesn't exist: it is saved under the category where `+` was tapped.
4. The tag is toggled in the story and the grid is refreshed.

### Tag Ordering

When saving tags to a story, `BaseStoryViewModel.setTags()` automatically reorders the tag IDs: emoji/sticker tags (sorted by `categoryId`) come first, followed by normal text tags. Tag IDs are validated against a **fresh DB read** (not the debounced in-memory snapshot) so newly created custom emoji tags are never filtered out.

### Integration Points

- **Show Story Page** — tag and sticker buttons in the story header
- **Edit Story Page** — same access via story header
- **Story Tile** — sticker emojis shown inline (read-only)
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
| `lib/widgets/sp_floating_tag_picker.dart`                       | Floating text tag picker with fuzzy search         |
| `lib/widgets/sp_emoji_tag_picker.dart`                          | Floating sticker picker with custom emoji support  |
| `lib/widgets/sp_story_labels.dart`                              | Inline sticker/tag display in story header         |
| `lib/views/stories/local_widgets/story_header.dart`             | Passes `onToggleTags` to labels                    |
| `lib/views/stories/local_widgets/base_story_view_model.dart`    | `setTags()` with emoji-first reordering            |
| `lib/providers/tags_provider.dart`                              | `emojiById` map, `setAllTags()`, `createTag()` API |

## Translation Keys

- `general.tag_category.feeling` — "Feeling" category name
- `general.tag_category.activity` — "Activity" category name
- `page.tags.title` — "Tags" label (existing)
- `page.new_tag.title` — "New Tag" button (existing)
