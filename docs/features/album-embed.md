# Album Embed (Multi-Image Block)

## Overview

Albums allow multiple images to be stored in a single Quill embed block, displayed as a responsive grid layout.

## Data Format

Albums reuse the existing `"image"` embed key with pipe-delimited (`|`) paths:

```json
// Single image (unchanged)
{ "insert": { "image": "images/123.jpg" } }

// Album (2+ images)
{ "insert": { "image": "images/123.jpg|images/456.jpg|images/789.jpg" } }
```

**Why pipe delimiter?** Simpler than JSON, safe because file paths and URLs cannot contain unencoded `|`.

## Grid Layouts

`SpAlbumGrid` renders different layouts based on image count:

| Count | Layout                                       |
| ----- | -------------------------------------------- |
| 0     | Hidden (`SizedBox.shrink`)                   |
| 1     | Square aspect ratio                          |
| 2     | Side-by-side row                             |
| 3     | Large left (2/3) + 2 stacked right (1/3)     |
| 4     | 2×2 grid                                     |
| 5     | Tall left (1/2) + 2×2 grid right (1/2)       |
| 6+    | 2 rows × 3 columns, `+N` overlay on 6th cell |

## Embed Attributes

- **Alignment**: `left`, `center`, `right` (stored in `_EmbedAlignmentAttribute`)
- **Size**: Toggle between constrained width and full-width (`_EmbedSizeAttribute.maxSize`)

## Key Files

| File                                                                          | Purpose                                          |
| ----------------------------------------------------------------------------- | ------------------------------------------------ |
| `lib/widgets/sp_album_grid.dart`                                              | Reusable grid layout widget                      |
| `lib/widgets/bottom_sheets/sp_album_management_sheet.dart`                    | Reorder, delete, add, preview photos             |
| `lib/core/rich_text/flutter_quill/custom_embeds/quill_image_block_embed.dart` | Quill embed renderer (single + album)            |
| `lib/widgets/bottom_sheets/sp_image_picker_bottom_sheet.dart`                 | Image picker, joins paths with `\|`              |
| `lib/core/services/assets/asset_link_parser.dart`                             | Splits on `\|` when extracting asset IDs/sources |
| `lib/core/services/quill/quill_delta_to_plain_text_service.dart`              | Splits on `\|` for markdown export               |

## User Flow

1. **Insert**: Pick images from library/device → paths joined with `|` → single embed inserted
2. **Convert to album**: Single image → more-vert menu → add photo → becomes album
3. **Manage album**: Album → more-vert menu → edit → opens management sheet (reorder, delete, add)
4. **View**: Read-only mode → tap grid cell → opens `SpImagesViewer` at that index

## Design Trade-offs

**The pipe-delimited format is intentionally simple.** Pros and cons:

### Pros

| Strength                           | Why it matters                                                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Zero migration cost                | Existing single-image deltas are 100% unchanged — no backfill needed                                    |
| Backward compatible reads          | Old code reading `node.value.data` gets the full string harmlessly (displays broken image, not a crash) |
| Safe delimiter                     | `\|` is forbidden in local file paths on all OSes and isn't used in internal asset paths                |
| Single parse point                 | `_parsePaths` is the only entry point — easy to test, easy to swap later                                |
| No new embed key or toolbar button | Reuses existing `"image"` infrastructure entirely                                                       |

### Cons / Accepted trade-offs

**Known trade-offs and why they are acceptable:**

| Concern                                          | Status                                                                                                                                       |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| No per-image metadata (captions, alt text, crop) | **Mitigated** — `AssetDbModel` (ObjectBox) is the source of truth for per-asset metadata. The embed path is just a key to look up the asset. |
| External URLs with encoded `\|`                  | **Not applicable** — this embed is designed for internal asset paths only (`images/`, `audio/`). External URLs go through a separate flow.   |
| Unbounded length / all-or-nothing undo           | **Accepted trade-off** — albums are typically small (< 20 images). Undo granularity at the block level is acceptable.                        |
| No "1-image album" concept                       | **Accepted** — a single path is always a single-image embed. Album UI only activates at 2+ images.                                           |

**Migration path if structured format is ever needed:** Any `"image"` value containing `|` is an album. A migration can convert them to a new `"album"` embed key with minimal effort since `_parsePaths` is the single parse entry point.
