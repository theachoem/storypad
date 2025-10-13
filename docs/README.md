# StoryPad Documentation

{{ ... }}
**LLM-optimized documentation for AI agents and developers.**

## Quick Navigation

### Guides

- **[Creating Features](guides/creating-features.md)** → Step-by-step feature creation
- **[Code Patterns](guides/code-patterns.md)** → Common code snippets
- **[Commands](guides/commands.md)** → Flutter commands
- **[Conventions](guides/conventions.md)** → File locations and naming

### Core

- **[Architecture](core/architecture.md)** → State management, MVVM
- **[File Organization](core/file-organization.md)** → Project structure
- **[Backup System](core/backup-system.md)** → Backup/sync with Google Drive

### Development

- **[Dependencies](development/dependencies.md)** → Package management
- **[Testing Basics](development/testing-basics.md)** → Test patterns and structure
- **[Mocking](development/mocking.md)** → Mockito usage
- **[Test Coverage](development/test-coverage.md)** → Coverage and best practices
- **[iOS Config](development/ios-config.md)** → iOS-specific configuration
- **[Android Config](development/android-config.md)** → Android-specific configuration
- **[Platform Patterns](development/platform-patterns.md)** → Platform-adaptive code

### UI

- **[Icons](ui/icons.md)** → SpIcons usage
- **[Platform-Specific](ui/platform-specific.md)** → Adaptive widgets
- **[Widget Organization](ui/widget-organization.md)** → Reusable vs local widgets
- **[Styling](ui/styling.md)** → Theme and responsive design
- **[Common Widgets](ui/common-widgets.md)** → UI widgets

### Product

- **[Overview](product/overview.md)** → Product identity, mission, platforms
- **[Metrics](product/metrics.md)** → User base, growth, performance
- **[Roadmap](product/roadmap.md)** → Features, upcoming development
- **[Marketing Guide](product/marketing-guide.md)** → Brand positioning, messaging
- **[User Personas](product/user-personas.md)** → Target audience, use cases

### Add-ons

- **[Add-ons Overview](add-ons/README.md)** → Philosophy, pricing, implementation
- **[Relaxing Sounds](add-ons/relaxing-sounds.md)** → Ambient audio for writing
- **[Templates](add-ons/templates.md)** → Reusable writing structures

## For LLM Agents

This documentation is optimized for token efficiency and context priming:

1. **Topic-based splitting** → Load only relevant docs
2. **Concise formatting** → Minimal tokens, maximum information
3. **Code examples** → Practical patterns from codebase
4. **Quick reference** → Tables and lists for fast scanning

### When to Read What

| Task                  | Read                                                                                    |
| --------------------- | --------------------------------------------------------------------------------------- |
| Creating new feature  | [Creating Features](guides/creating-features.md) + [Architecture](core/architecture.md) |
| Code snippets         | [Code Patterns](guides/code-patterns.md)                                                |
| Flutter commands      | [Commands](guides/commands.md)                                                          |
| File locations/naming | [Conventions](guides/conventions.md)                                                    |
| Adding UI components  | [Icons](ui/icons.md) + [Common Components](ui/common-components.md)                     |
| Platform-specific UI  | [Platform-Specific](ui/platform-specific.md)                                            |
| Adding dependencies   | [Dependencies](development/dependencies.md)                                             |
| Writing tests         | [Testing Basics](development/testing-basics.md) + [Mocking](development/mocking.md)     |
| iOS setup             | [iOS Config](development/ios-config.md)                                                 |
| Android setup         | [Android Config](development/android-config.md)                                         |
| Backup/sync features  | [Backup System](core/backup-system.md)                                                  |
| Planning features     | [Roadmap](product/roadmap.md) + [User Personas](product/user-personas.md)               |
| Marketing content     | [Marketing Guide](product/marketing-guide.md) + [Overview](product/overview.md)         |
| Growth analysis       | [Metrics](product/metrics.md)                                                           |
| Add-on development    | [Add-ons Overview](add-ons/README.md)                                                   |

## Documentation Principles

1. **Lean & Concise** → Every word counts
2. **Example-driven** → Show, don't just tell
3. **Scannable** → Tables, lists, code blocks
4. **Contextual** → Link to actual codebase files
5. **Up-to-date** → Reflects current implementation

## Contributing to Docs

See **[Contributing to Documentation](contributing-to-docs.md)** for:

- How to add new documentation
- Folder structure and naming conventions
- LLM-friendly writing guidelines
- Documentation checklist
