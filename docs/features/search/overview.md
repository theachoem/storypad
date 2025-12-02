# Search System Overview

## 📚 Table of Contents

- [Introduction](#introduction)
- [Architecture](#architecture)
- [Search Indexing](#search-indexing)
- [Search Filtering](#search-filtering)

---

## Introduction

StoryPad's search system enables users to find stories quickly through text search and advanced filtering. The system uses **ObjectBox's full-text search** capabilities combined with a pre-computed search metadata index for optimal performance.

---

## Architecture

### Core Components

```
┌─────────────────────────────────────────────────────┐
│                  Search UI Layer                     │
│  • SearchView/SearchViewModel                       │
│  • SearchFilterView/SearchFilterViewModel           │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              Search Filter Object                    │
│  • SearchFilterObject: Query parameters             │
│  • SearchFilterStorage: Persists filters            │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              Database Layer                          │
│  • StoriesBox#buildQuery()                          │
│  • StoryObjectBox.searchMetadata (indexed field)    │
└─────────────────────────────────────────────────────┘
```

### File Structure

| Component        | Path                                                             | Purpose                      |
| ---------------- | ---------------------------------------------------------------- | ---------------------------- |
| Search UI        | `lib/views/search/`                                              | User interface for searching |
| Filter UI        | `lib/views/search/filter/`                                       | Advanced filter controls     |
| Filter Object    | `lib/core/objects/search_filter_object.dart`                     | Search parameters model      |
| Filter Storage   | `lib/core/storages/search_filter_storage.dart`                   | Persists user preferences    |
| Database Queries | `lib/core/databases/adapters/objectbox/stories_box.dart`         | Query builder                |
| Text Extraction  | `lib/core/services/quill/quill_delta_to_plain_text_service.dart` | Converts Quill to text       |

---

## Search Indexing

### How It Works

StoryPad uses a **pre-computed search metadata** approach for efficient text search:

1. **Index Generation** (`searchMetadata` field)

   - When a story is saved, all page titles and body text are extracted
   - Quill Delta format is converted to plain text using `QuillDeltaToPlainTextService`
   - Combined into a single searchable string
   - Stored in `StoryObjectBox.searchMetadata`

2. **Search Query**
   - User types search query → `SearchFilterObject.query`
   - ObjectBox performs case-insensitive substring match on `searchMetadata`
   - Results returned instantly (no runtime text extraction needed)

### Index Structure

```dart
// Example searchMetadata content:
"""
My Vacation 2024
Had an amazing time at the beach. The weather was perfect.
Day 2
Went snorkeling and saw beautiful coral reefs.
"""
```

### Code Flow

```dart
// 1. Text Extraction (when saving story)
StoryContentDbModel.generateBodyPlainText()
  → QuillDeltaToPlainTextService.call(page.body)
  → Returns plain text from Quill Delta JSON

// 2. Index Generation (in StoriesBox)
_generateSearchMetadata(content)
  → Combines: content.title + content.plainText
  → Stored in StoryObjectBox.searchMetadata

// 3. Search Query (when user searches)
SearchViewModel.searchText(query)
  → SearchFilterObject.query = query
  → StoriesBox.buildQuery(filters: {'query': query})
  → StoryObjectBox_.searchMetadata.contains(query, caseSensitive: false)
```

### Reindexing Legacy Data

For stories created before the search metadata system, a migration process regenerates indexes:

```dart
// Called on search view initialization
StoryDbModel.db.reindexSearchMetadata()
```

**Process:**

1. Find stories with `searchMetadata == null`
2. Extract content from `draftContent` or `latestContent`
3. Regenerate `searchMetadata` using `_generateSearchMetadata()`
4. Batch update (50 stories at a time for performance)

---

## Search Filtering

### SearchFilterObject

Comprehensive filter model with multiple dimensions:

```dart
SearchFilterObject({
  Set<int> years,           // Filter by year(s)
  Set<int>? excludeYears,   // Exclude specific years
  String? query,            // Text search query
  int? month,               // Filter by month (1-12)
  int? day,                 // Filter by day (1-31)
  Set<PathType> types,      // docs/bins/archives
  int? tagId,               // Filter by tag
  int? assetId,             // Filter by voice/asset
  int? templateId,          // Stories from template
  int? eventId,             // Stories linked to event
  String? galleryTemplateId,// Gallery template stories
  bool? starred,            // Only starred stories
  int? limit,               // Max results
})
```

### Filter UI Features

**Quick Filters:**

- Tag chips (horizontally scrollable)
- Year selection (multi-select or single)
- Starred toggle

**Advanced Filters:**

- Type selection (docs/bins/archives)
- Month/day picker (for specific dates)
- Template/event/asset filtering

### Query Builder

`StoriesBox.buildQuery()` translates filters to ObjectBox conditions:

```dart
// Example: Search "beach" in 2024, tagged "Vacation"
filters = {
  'query': 'beach',
  'years': [2024],
  'tag': 5,
  'types': ['docs']
}

// Becomes ObjectBox query:
StoryObjectBox_.searchMetadata.contains('beach', caseSensitive: false)
  .and(StoryObjectBox_.year.oneOf([2024]))
  .and(StoryObjectBox_.tags.containsElement('5'))
  .and(StoryObjectBox_.type.oneOf(['docs']))
```

### Filter Persistence

- **Full filter state** saved to `SearchFilterStorage` (local storage)
- **Tag selection only** restored when reopening search
- Other filters reset to defaults (better UX - less confusion)

```dart
// Save
SearchFilterStorage().writeObject(searchFilter);

// Restore (tag only)
searchFilter = initialFilter.copyWith(
  tagId: savedFilter?.tagId
);
```

## Implementation Guidelines

## Performance Considerations

### ✅ Optimizations

- Pre-computed search index (no runtime text extraction)
- Batch reindexing (50 stories at a time)
- Lazy loading (only when search view opens)
- Debounced search input (avoid excessive queries)
- Result limiting (default 100 items)

### 📊 Query Complexity

- **Simple text search:** O(n) substring match (ObjectBox indexed)
- **Multi-filter query:** Combines conditions efficiently
- **Tag filtering:** Integer array containment (fast)
- **Year range:** Between operator (optimized)
