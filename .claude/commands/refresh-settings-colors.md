---
description: Renumber settings tile badge colors into a continuous 1→7 rainbow cycle
argument-hint: "(optional notes, e.g. 'just added Day Colors tile after ColorSeed')"
allowed-tools: Read, Edit, Bash(flutter analyze:*)
---

You maintain the weekday badge colors in the Settings page so they flow as a single, continuous 1→7 rainbow down the whole page.

## Context

- Settings tiles render a colored badge via `SpSettingIconBadge(weekday: N, ...)`, where `weekday` (1–7) maps to a day color from `ColorFromDayService` / `kDefaultColorNamesByDay`. The number is purely the visual color slot, not a real weekday.
- Some tiles set `weekday` directly inline; others take it as a constructor arg (e.g. `FontSizeTile.globalTheme(weekday: N)`, `LanguageTile(weekday: N)`, `buildAppLockTile(context, weekday: N)`); a few hardcode it inside their own widget file (e.g. `QuickActionsTile` in `lib/views/settings/local_widgets/quick_actions_tile.dart`).
- Tiles **without** an `SpSettingIconBadge` (e.g. `ColorSeedTile`, `AppIconTile`, plain dividers/section titles) use custom leading widgets and are **skipped** — they do not consume a slot in the cycle.

## Task

$ARGUMENTS

1. Read `lib/views/settings/settings_content.dart` top to bottom. Build the ordered list of every tile that shows an `SpSettingIconBadge`, in visual order, including ones whose badge lives in a separate widget file (open those files to confirm — e.g. `QuickActionsTile`).
2. Assign `weekday` sequentially starting at **1** for the first badged tile, incrementing by 1 for each subsequent badged tile, and **wrapping 7 → 1**. Skip non-badged tiles entirely.
3. Apply the new numbers:
   - Edit `settings_content.dart` for inline/arg-based tiles.
   - Edit the relevant `local_widgets/*.dart` file for any tile that hardcodes its own `weekday` (e.g. `quick_actions_tile.dart`).
4. Run `flutter analyze lib/views/settings` and confirm no issues.
5. Report the final tile → weekday mapping as a table, and note any tiles you skipped (and why).

Do not change icons, titles, routing, or tile order — only the `weekday` color slots.
