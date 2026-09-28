# storypad_editor

A controller-centric rich text editor for StoryPad, built on
[super_editor](https://github.com/Flutter-Bounty-Hunters/super_editor):

- **Markdown in, Markdown out.** Markdown is the only format written; formats CommonMark lacks use HTML5 tags. Writing
  is a fixed point, so an opened-and-saved story never changes by itself.
- **Quill Delta import and export**, for stories stored as Quill: open them here, and write them back as Quill until
  storage moves to Markdown.
- **App-defined embeds.** Each embed (media, audio, …) is one object bundling its Quill form, Markdown form and
  widget. All embeds go into one controller; the editor widgets take the controller, and the controller does the rest.

Not published to pub. `example/` is the manual-test app and reference consumer. See [FEATURES.md](FEATURES.md) for
the storage format, design decisions and gotchas.

## Use

```yaml
dependencies:
  storypad_editor:
    git:
      url: https://github.com/theachoem/storypad_editor.git
      ref: <commit>
```

**Android:** super_editor's `super_keyboard` plugin pins compileSdk 34, which newer transitive plugins reject
(`checkAarMetadata`: "requires … compileSdk of at least 36"). Until it's updated upstream, raise plugin modules'
compileSdk in the app's `android/build.gradle.kts`, before its `evaluationDependsOn(":app")` block — copy the
`subprojects { afterEvaluate { … } }` block from `example/android/build.gradle.kts`. (Its Kotlin Gradle Plugin warning
is harmless for now.)

### 1. Define embeds

```dart
class AudioEmbed extends StoryEmbed<String> {
  const AudioEmbed();

  @override String get type => 'audio';                 // unique; also the block type for styling
  @override Set<String> get quillKeys => const {'audio'};  // Quill ops it imports
  @override Set<String> get htmlTags => const {'audio'};   // Markdown lines it reads

  @override
  String? fromQuill(QuillEmbedOp op) => op.value is String ? op.value as String : null;

  @override
  QuillEmbedOp toQuill(String path) => QuillEmbedOp.of('audio', path);   // the mirror of fromQuill

  @override
  String? fromHtml(StoryHtmlElement element) => element['src'];

  @override
  StoryHtmlElement toHtml(String path) => StoryHtmlElement('audio', attributes: {'controls': '', 'src': path});

  @override
  Widget build(BuildContext context, StoryEmbedContext<String> embed) => VoicePlayer(
    path: embed.value,
    onRemove: embed.readOnly ? null : embed.remove,   // embed.update(...) edits the value
  );
}
```

Values need `==`/`hashCode`. Attributes that exist in both formats are declared once with `StoryEmbedAttribute`
(e.g. Quill's `custom-embed-alignment` ↔ HTML `data-align`; `toQuill`/`toHtml` spread them in). Returning `null` from
`fromQuill`/`fromHtml` never loses data: the built-in unknown embed keeps it verbatim.

### 2. Edit

```dart
final controller = StoryEditorController(embeds: const [MediaEmbed(), AudioEmbed()], markdown: story.body);
// or StoryEditorController.fromQuill(story.deltaOps, embeds: ...)

MarkdownEditor(controller: controller, onChanged: (markdown) => story.save(body: markdown), onTapLink: openLink);
// or RawEditor(controller: controller), and read controller.toMarkdown() yourself

controller.actions.toggleBold();
controller.insertEmbed(const AudioEmbed(), 'audio/1.m4a');
controller.readOnly = true;       // a reader; checkboxes stay live
controller.isDirty;               // compared as canonical Markdown
controller.dispose();             // after the editor widget is gone
```

To open another story, create a new controller (key the editor with it); content is never swapped in place.

Presentation, on either editor widget:

- `layout`: `StoryEditorLayout.scrolling` (fills its box, scrolls itself), `.box` (sized to its content inside your
  scroll view, e.g. below a title field; that scroll view scrolls it and follows the caret), or `.sliver` (several
  editors in one `CustomScrollView`).
- `baseTextStyle`, `styleRules`, `padding`; `caretColor`/`selectionColor` (default: the theme's `TextSelectionTheme`,
  else its primary color); `placeholder`; `checkboxesEnabled: false` for a view that won't keep its changes;
  `contextMenuActions` — extra selection-menu items (e.g. Uppercase via `actions.transformSelectedText`).

### 3. Toolbars

The package has no toolbar; build one from the controller (see `example/lib/toolbar/`):

- `controller.actions` — every command, and the state a button shows (`isBold`, `headingLevel`, `canIndent`, …),
  including caret moves for arrow buttons (`moveCaret`, `canMoveCaret`, `placeCaretAtEnd`).
- `ListenableBuilder(listenable: controller, …)` — rebuild on selection/document/style changes.
- `controller.isToolbarActive` — show a touch toolbar while editing.
- `TapRegion(groupId: controller.tapRegionGroupId, …)` — so tapping the toolbar doesn't unfocus the editor.
- `controller.holdSelection()` / `keepSelectionWhile(...)` — around any popup or dialog, taken before opening it, so
  the selection survives losing focus.

### Headless conversion

```dart
final codec = StoryCodec(embeds: const [MediaEmbed(), AudioEmbed()]);
final markdown = codec.quillToMarkdown(ops);
final text = codec.toPlainText(markdown);   // search, word counts

final losses = codec.quillImportLosses(ops);   // formatting the conversion would drop (empty = lossless)
final quill = codec.markdownToQuill(markdown); // back to Quill, in the shapes StoryPad's Quill editor writes
```

### Testing

`package:storypad_editor/testing.dart`: `expectEmbedRoundTrip` (checks an embed stores a value losslessly, in Markdown
and in Quill), `isEquivalentDocument`, `isEquivalentQuill` (two Deltas that mean the same story), `pumpStoryEditor`.

`package:storypad_editor/super_editor.dart` re-exports the exact super_editor version this package pins.

## Develop

```sh
flutter test --concurrency=1          # package (the default concurrent runner can drop files under load)
(cd example && flutter test --concurrency=1)
flutter analyze && (cd example && flutter analyze)
dart format -l 120 lib test
```

**Fidelity audit**: how real stories survive Quill → Markdown → Quill (what the bridge phase does on every save).
Prints only counts, attribute keys and story ids, never story text; nothing leaves your machine:

```sh
cd example
BACKUP=/path/to/backup-file-or-folder flutter test tool/fidelity_audit_test.dart   # a StoryPad backup (gzip or JSON)
flutter test tool/fidelity_audit_test.dart                                        # the real-shape fixtures
```

It fails unless nothing is dropped. The report also lists embed ops written back differently with the same value
(e.g. the legacy `image` key becoming `media`), unknown embed keys, and conversion time per page.
