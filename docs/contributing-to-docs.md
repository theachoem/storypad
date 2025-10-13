# Contributing to Documentation

**Guide for maintaining and adding documentation in this project.**

## Documentation Structure

```
docs/
├── README.md                    # Main navigation hub
├── guides/                      # How-to guides and quick references
│   └── quick-reference.md
├── core/                        # Core system architecture and organization
│   ├── architecture.md
│   ├── file-organization.md
│   └── backup-system.md
├── development/                 # Development setup and tooling
│   ├── dependencies.md
│   ├── platform-config.md
│   └── testing.md
└── ui/                          # UI patterns and components
    └── ui-patterns.md
```

## Folder Categories

### `guides/`

**Purpose**: Quick-start guides, checklists, common tasks  
**When to add**: Step-by-step tutorials, quick reference materials  
**Naming**: `{topic}-guide.md`, `quick-reference.md`

### `core/`

**Purpose**: Fundamental system architecture, organization, critical systems  
**When to add**: Architecture decisions, system design, core workflows  
**Naming**: `{system-name}.md` (e.g., `architecture.md`, `backup-system.md`)

### `development/`

**Purpose**: Development environment, tooling, dependencies, configuration  
**When to add**: Setup instructions, dependency docs, platform configs  
**Naming**: `{tool-or-topic}.md` (e.g., `dependencies.md`, `testing.md`)

### `ui/`

**Purpose**: UI patterns, components, design system  
**When to add**: Widget patterns, styling guides, UI conventions  
**Naming**: `{ui-topic}.md` (e.g., `ui-patterns.md`, `components.md`)

## Adding New Documentation

### 1. Choose the Right Folder

Ask yourself:

- **Is it a how-to guide?** → `guides/`
- **Is it about core architecture/systems?** → `core/`
- **Is it about dev setup/tooling?** → `development/`
- **Is it about UI/components?** → `ui/`

### 2. File Naming Convention

**LLM-friendly naming rules:**

- Use lowercase with hyphens: `my-topic.md`
- Be descriptive but concise: `state-management.md` not `sm.md`
- Use searchable keywords: `firebase-setup.md` not `setup.md`
- Avoid abbreviations unless widely known

**Examples:**

- ✅ `authentication-flow.md`
- ✅ `database-schema.md`
- ✅ `ci-cd-pipeline.md`
- ❌ `auth.md` (too vague)
- ❌ `db_schema.md` (use hyphens, not underscores)
- ❌ `my_new_doc.md` (use hyphens)

### 3. Document Structure

Every documentation file should follow this structure:

```markdown
# Title

**One-line description of what this document covers.**

## Section 1

Content with code examples...

## Section 2

More content...

## See Also

- [Related Doc 1](../folder/related-doc.md)
- [Related Doc 2](../folder/another-doc.md)
```

### 4. Writing Style

**For LLM optimization:**

- **Concise**: Every word counts, minimize token usage
- **Scannable**: Use tables, lists, code blocks
- **Example-driven**: Show real code from the codebase
- **Linked**: Reference actual files with relative paths
- **Structured**: Use clear headings and sections

**Example:**

````markdown
## Adding a New Feature

### 1. Create View

```dart
// lib/views/my_feature/my_feature_view.dart
class MyFeatureView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyFeatureViewModel(),
      child: MyFeatureContent(),
    );
  }
}
```
````

### 2. Create ViewModel

See [architecture.md](../core/architecture.md) for ViewModel patterns.

````

### 5. Update Main README

After adding a new doc, update `docs/README.md`:

1. Add link in the appropriate section
2. Add entry in "When to Read What" table if applicable
3. Keep alphabetical order within sections

### 6. Internal Links

**Always use relative paths:**
- Same folder: `[Link](file.md)`
- Parent folder: `[Link](../README.md)`
- Sibling folder: `[Link](../other-folder/file.md)`

**Examples:**
```markdown
<!-- From guides/quick-reference.md -->
See [Architecture](../core/architecture.md) for details.

<!-- From core/architecture.md -->
See [Quick Reference](../guides/quick-reference.md) for examples.

<!-- From any file to main README -->
See [Documentation Index](../README.md).
````

## Documentation Checklist

When adding or updating documentation:

- [ ] File is in the correct folder (`guides/`, `core/`, `development/`, `ui/`)
- [ ] Filename uses lowercase with hyphens
- [ ] Filename is descriptive and searchable
- [ ] Document has a clear title and one-line description
- [ ] Content is concise and scannable
- [ ] Code examples are from actual codebase
- [ ] Internal links use relative paths
- [ ] Main `README.md` is updated with new doc link
- [ ] Cross-references to related docs are added

## LLM Search Optimization

To make docs easily discoverable by AI assistants:

### Use Searchable Keywords

Include common search terms in:

- Filename
- Title
- First paragraph
- Section headings

**Example:**

```markdown
# State Management with Provider

**Flutter state management using Provider and ChangeNotifier pattern.**

This document covers:

- Provider setup and configuration
- ChangeNotifier pattern
- State hierarchy (app, view, widget)
- MVVM architecture with Provider
```

### Avoid Ambiguous Names

- ❌ `setup.md` → ✅ `firebase-setup.md`
- ❌ `patterns.md` → ✅ `ui-patterns.md`
- ❌ `config.md` → ✅ `platform-config.md`

### Include Context in Headings

- ❌ `## Usage` → ✅ `## Provider Usage Patterns`
- ❌ `## Setup` → ✅ `## Firebase Setup Steps`
- ❌ `## Examples` → ✅ `## ViewModel Examples`

## Maintenance

### Regular Reviews

- Keep docs in sync with code changes
- Remove outdated information
- Update code examples when APIs change
- Verify all internal links work

### When Code Changes

If you change code that's documented:

1. Update relevant documentation
2. Update code examples
3. Verify links still work
4. Check cross-references

## Questions?

See [README.md](README.md) for documentation index or raise an issue.
