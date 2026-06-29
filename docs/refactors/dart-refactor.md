# Dart Refactor Guidelines

Use this checklist when refactoring Dart/Flutter UI. When a refactor reveals a reusable rule, add it here so future Copilot, Cursor, and Claude sessions can keep improving the same guidance.

Important: keep each rule to a single line; only add extra explanation when it is truly necessary.

## Layout

- Prefer `Row/Column(spacing: ...)` over repeated `SizedBox` gaps when Flutter version supports it.
- Replace `SizedBox + Padding` wrappers with one `Container` only when it improves readability.
- Keep spacing on the 4px scale: `4/8/12/16/20/24/32`.
- Keep border radius on the 4px scale `4/8/12/16`, and only use non-scale values when necessary, e.g. derived inner radius `16 - 2 = 14` or full-pill values.
- Avoid custom `ScrollPhysics` like `BouncingScrollPhysics` unless behavior must differ from platform defaults.

## Dart Style

- Name private local widgets `_WidgetName` (PascalCase); name widget-returning helper methods with a `_build` prefix, e.g. `_buildHeader`, never bare `_header`.
- Prefer Dart enum/value shorthand like `.start`, `.center`, `.horizontal` when the type is obvious.
- Prefer `const` constructors/literals wherever analyzer allows.
- Keep single-property or single-argument calls on one line with no trailing comma, e.g. `style: TextTheme.of(context).titleMedium?.copyWith(fontWeight: FontWeight.w800)`.
- For named-parameter constructors, prefer multiline parameter lists with a trailing comma (even with one parameter) so the formatter keeps them expanded.
- For local helper methods, use named parameters when there is more than one argument; keep positional parameters only for simple single-argument helpers unless naming materially improves clarity.
- Shared UI widgets should accept display-ready presentation models instead of raw domain objects when labels, statuses, and totals are derived by view state.

## Theme And Colors

- Extract repeated `Theme.of(context).colorScheme` / `ColorScheme.of(context)` into locals per build method.
- Use `Theme.of(context).dividerColor` for border colors.
- Use `ColorScheme.of(context)` to access color scheme.
- Use `TextTheme.of(context)` to access text theme.

## Localization

- Pass the key to `tr('literal.key')` / `plural('literal.key')` as a string literal, never `tr(someVariable)` — the unused-translations scanner (`test/unused_translations_test.dart`) only detects literal keys.
- For enum/model-driven labels, resolve the text in a `switch` that returns literal `tr('...')` calls (e.g. a `label` getter), rather than storing a key string and calling `tr(key)`.

## Workflow

- Use a two-phase refactor flow: first finish and approve the Dart/UI refactor pass, then run a second pass to extract pieces into `<view>/local_widgets/`.
- In the extraction pass, prefer `part` / `part of` files to keep view-specific helper widgets private to the parent view when they are not shared.
- Put bottom sheets in `lib/widgets/bottom_sheets/` with an `Sp` prefix (e.g. `SpToggleListSheet`) so they live in one discoverable place and can be reused as examples; keep them decoupled from view models — pass plain values + callbacks (and an optional `Listenable` for live updates), not the view model itself.
- Format with `./bin/format` (runs `dart format --line-length=120` over `lib/` and `test/`, excluding generated files) rather than calling `dart format` directly.
