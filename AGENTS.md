# AGENTS.md

Standard instructions for AI coding agents (GitHub Copilot, Cursor, etc.).
Claude Code reads `CLAUDE.md` directly, so keep both in sync when these rules change.

## For Implementation Tasks

1. Read `docs/README.md` to identify which docs to load
2. Load specific guides from `docs/{guides,core,development,ui}/`
3. Follow established patterns from documentation

## Critical Rules

- ❌ **NEVER** put a condition inside `tr()` (a script scans literal `tr("key")` calls) → ✅ `cond ? tr("a") : tr("b")`, not `tr(cond ? "a" : "b")`
- ❌ **NEVER** use `Icons.*` or `CupertinoIcons.*` → ✅ Use `SpIcons.*`
- ✅ Use **Provider + ChangeNotifier** for state management
- ✅ Follow **MVVM** structure: View + ViewModel + Content
- ✅ Use `adaptive_dialog` for dialogs
- ✅ Check `docs/development/dependencies.md` before adding packages

## Quick Reference

| Task            | Read                                                                         |
| --------------- | ---------------------------------------------------------------------------- |
| New feature     | `docs/guides/creating-features.md` + `docs/core/architecture.md`             |
| Code snippets   | `docs/guides/code-patterns.md`                                               |
| UI icons        | `docs/ui/icons.md`                                                           |
| UI widgets      | `docs/ui/common-widgets.md` (preferred term: use 'widgets' not 'components') |
| Testing         | `docs/development/testing-basics.md` + `docs/development/mocking.md`         |
| Platform config | `docs/development/ios-config.md` or `docs/development/android-config.md`     |

## Doc Checklist (auto-follow):

1. Concise content for LLM efficiency
2. Filenames: lowercase-with-dashes, keyword-rich (`docs/core/architecture.md`)
3. Validate against existing docs for compliance
4. In-progress work: plan/design docs go in `docs/implementations/<feature>/plan.md`, not `docs/features/`
5. Only add a `docs/features/<feature>.md` user guide once that feature is fully complete and stable

## Agent Rules:

- Keep rules concise - detailed docs belong in README.md and docs/
- Only include pointers and checklists, not full explanations
- When docs change, IMMEDIATELY update both `AGENTS.md` and `CLAUDE.md`
