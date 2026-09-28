# Features, format and gotchas

Pointer-style: see the named files for how each works. Update when behavior changes.

## Architecture

- **Embed contract** (`lib/src/embed/`): `StoryEmbedCodec<T>` (Quill op both ways, Markdown HTML, plain text — headless) and
  `StoryEmbed<T>` (+ `build`). One package-owned, non-generic `StoryEmbedNode(type, value)`: super_editor compares
  nodes and view models by `runtimeType`, so a generic node would silently compare unequal across copies.
  `StoryEmbedRegistry` validates types, Quill keys and tags up front (duplicates, reserved names).
- **Codec** (`lib/src/codec/story_codec.dart`): `decode`/`encode`/`quillToMarkdown`/`markdownToQuill`/
  `quillImportLosses`/`toPlainText`, no widgets.
- **Controller** (`lib/src/controller/`): owns document, composer and an `Editor` it builds itself (see Gotchas),
  `StoryEditorActions` (headless commands), embed ops, selection holds, dirty tracking, read-only.
- **Widgets** (`lib/src/widgets/`): `RawEditor`, `MarkdownEditor`, and one `StoryEmbedComponentBuilder` for every
  embed. No toolbar: `example/lib/toolbar/` is the reference.

## Storage format (Markdown)

Written by `markdown/markdown_writer.dart`, read by `markdown/markdown_reader.dart` (a small line-based block parser;
inline content uses `package:markdown`'s CommonMark inline parser). Guarantee, checked by randomized tests:
`decode(encode(doc))` ≡ `doc` and `encode(decode(encode(doc))) == encode(doc)`.

- Every block is one line, except fenced code (fence longer than any backtick run inside) and the wrapper below.
  Blocks are separated by a blank line; consecutive list items/tasks by one newline.
- Hard line break inside text: `<br>`. Empty paragraph: `&nbsp;`. Trailing empty paragraphs are dropped.
- Lists/tasks: `-`, `1.`, `- [ ]`/`- [x]`, 4 spaces per level (reads 2/3-space nesting too). Indent max 6.
- Non-left alignment and paragraph indent: `<div style="text-align:…" data-indent="…">` + blank lines + the block +
  blank lines + `</div>` (paragraphs, headings, quotes). A run of consecutive list items/tasks sharing an alignment
  is one wrapper around the whole run (their indent is their nesting). Code has neither.
- Inline: `**`, `*`, `~~`, `` ` ``, `[](…)`, plus `<u>`, `<span style="color:#rrggbbaa">`,
  `<mark style="background-color:#rrggbbaa">`, `<sup>`, `<sub>`. When CommonMark's emphasis rules would misread a
  delimiter (e.g. `**(a)**b`), the line falls back to `<strong>`/`<em>`/`<del>`: every written line is parsed back
  and compared (`inline_markdown_writer.dart`).
- Escaping: Markdown punctuation with `\`, `<` `>` `&` and backticks as references; block syntax at line start
  (`#`, `-`, `+`, `1.`, `=`); trailing spaces/tabs as references (tools trim them); `\r`, U+2028, U+2029 as
  references (they'd split or end a line). Link and stock-image destinations are written normalized (Markdown
  percent-encodes spaces). A code span inside an HTML-tag format is `<code>` with escaped content (a backtick span
  could contain the tag's closing tag). CRLF input reads as LF; code blocks normalize line endings.
- Embeds: one line of HTML from `toHtml`; an `<img>` with only `src`/`alt` is written `![alt](src)` when that reads
  back identically, and a bare `![]()` reads through the embed claiming `img`.
- Unknown: a Quill op no embed claims → `<sp-unknown data-op="base64(json(op))">` (attributes included), read by
  whichever embed imports its key once one is registered. A Markdown line that is exactly one element no embed
  claims (a newer app's embed, `<video>` in an app without a media embed, …), a line an embed rejects, or any `<sp-*>`
  line → kept verbatim. Only formatting tags (`<p>`, `<u>`, `<br>`, …) read as text.
- Reading never throws: an embed whose `fromQuill`/`fromHtml` throws is treated as rejecting (reported via
  `FlutterError.reportError`), and conflicting nested markup (a link in a link, `<sub>` in `<sup>`) keeps the inner
  value.

## Quill import (`quill/quill_importer.dart`)

- Embeds only through the registry (no stock image/video/audio/file formats); unclaimed or rejected → unknown.
- One combined block format (header, list/task, quote, code, indent, align): super_editor applies only the first
  matching block format per line, so stock formats drop combinations.
- Tolerant inline formats: stock color/link/script formats throw on a bad value and abort the whole import.
- Ops are sanitized (non-inserts skipped) and split per `\n` (Quill compacts same-attribute lines into one op).
- Removed after import: the empty paragraph super_editor inserts after every embed, and the one Quill's final `\n`
  opens.
- Consecutive quote lines merge into one quote (line breaks inside) only when they share alignment and indent;
  super_editor's own merge rule would keep only the first line's format.
- Alignment on any line but code, through `ChangeTextAlignmentRequest` (super_editor's alignment request only takes
  paragraphs); list items and tasks render it via the compact builders (stock ones ignore `textAlign`).
- Dropped by design (never produced by StoryPad's toolbar; none in a real backup audit): font, size, direction,
  a header on a list line, a code block's language, alignment/indent/formatting inside code.
- `quillImportLosses` (`quill/quill_import_losses.dart`) reports every drop above by applying the importer's rules; a
  property test ("no losses ⇒ the Quill round trip is equivalent") keeps the two in step.

## Quill export (`quill/quill_exporter.dart`)

For stories still stored as Quill: the mirror of the importer, in the shapes StoryPad's Quill editor writes.

- Blocks on each line's `\n`: `header`, `list` (+ `indent`), `blockquote: true`, `code-block: true`, `align`,
  `indent`. A node holding line breaks (a multi-line quote/code block, a soft break) becomes one Quill line per line.
- Inline: `bold`/`italic`/`underline`/`strike`/`code`/`script`/`link`, colors as lowercase `#aarrggbb`.
- Embeds through `toQuill`; a preserved Quill op verbatim. Horizontal rule ↔ `{"divider": "hr"}`. Anything without a
  Quill form (an embed without `toQuill`, a preserved Markdown line, a stock image) ↔ `{"sp-markdown": "<line>"}`,
  read back exactly. Both keys are reserved.
- Quill can't express a line break inside a list item or paragraph (they split into several), or a boundary between
  consecutive quotes sharing their format (they merge). Everything else round-trips; `isEquivalentQuill` (testing) compares two Deltas by
  meaning.

## Gotchas

- **One controller per story.** super_editor's undo replays history from a snapshot taken at construction, and history
  can't be cleared, so content is never replaced in place.
- **Editor reactions**: the controller leaves out `UpdateSubTaskIndentAfterTaskDeletionReaction` (re-clamps free task
  indent on any task delete) and `ImageUrlConversionReaction` (pasted URL → stock `ImageNode`).
- **Embed updates** use `UpdateStoryEmbedRequest` (a node change), not `ReplaceNodeRequest` (remove + insert, which
  triggers deletion reactions). `StoryEmbedContext.update` transforms the *live* value (fast double taps).
- **Revision/caching** listens to the document's change log, not editor listeners: undo/redo don't report edits to
  editor listeners.
- **Selection hold**: take it synchronously before opening a popup/dialog (opening moves focus). Mobile clears the
  selection on focus loss otherwise; `isToolbarActive` keeps a toolbar mounted meanwhile.
- **Embed host** paints its own selection overlay: super_editor's `SelectableBox` wraps its child in `IgnorePointer`.
- **Mobile reorder overlay** (`mobile_reorderable_document_overlay.dart`): while unfocused, opaque regions cover text
  blocks (they must win taps), so they forward vertical drags to the document's `ScrollPosition.drag` (otherwise it
  couldn't scroll), and re-measure after each scroll (post-frame: the overlay builds before the scrolled content is
  laid out). Embed regions are translucent so embed buttons get the first tap. `_safeSetState` guards gesture
  callbacks fired mid-rebuild.
- **`MarkdownEditor`** flushes a pending change on dispose/controller swap in a microtask (the tree is locked then);
  with `Duration.zero` it reports in a microtask too (edits in one synchronous block are reported once, and a
  callback that edits can't re-enter the editor mid-transaction).
- **`RawEditor`** caches its stylesheet and component builders: super_editor rebuilds its whole layout presenter
  whenever they aren't the same objects.
- **Code blocks** hold plain, unindented text: converting strips formatting, and inline/indent actions skip code.
- **package:markdown quirks** handled in the inline writer: no entity decoding right after a backtick (separator
  `<wbr>`), a backslash-escaped backtick before a code span breaks it, `!` right before a link makes an image.
- **Android toolbar** is super_editor's internal `AndroidPopoverToolbar`, vendored in `widgets/vendor/` (the
  `implementation_imports` lint is on).
- **Box layout** (`widgets/sliver_box.dart`): inside a scroll view super_editor renders its document as a *sliver* of
  that scroll view. `StoryEditorLayout.box` hosts the sliver in `SliverBox`, a plain render box laid out at the
  sliver's full length -- deliberately *not* a viewport: super_editor's mobile caret-follow measures against the
  nearest `RenderAbstractViewport`, so a `ShrinkWrappingViewport` host (which never scrolls) broke it, and nested
  viewports also trip Flutter's scroll-semantics assertion.
- **Caret/selection colors**: the desktop caret is a replaced `DefaultCaretOverlayBuilder` in the default overlay
  list (cached per color; super_editor rebuilds layers on a new list). Mobile carets/handles already use the theme's
  primary color.
- **iOS caret follow** happens on edits, not on programmatic caret moves (any layout); Android follows both.
- **Links** open through `RawEditor.onTapLink` (`widgets/link_tap_handler.dart`): on tap when read-only, on
  Cmd/Ctrl-click while editing (a plain tap places the caret); without a callback, `url_launcher` opens them.
- **Desktop context menu** is a hook (`RawEditor.desktopContextMenu`); the package ships no native code. The example
  wires a native macOS `NSMenu` (with the Services submenu) in `example/macos/Runner/MainFlutterWindow.swift`.

- **Android build**: `super_keyboard` (via super_editor) pins compileSdk 34; consuming apps must raise plugin modules to
  36 (see `example/android/build.gradle.kts` and the README) or AGP's `checkAarMetadata` fails.

## Known limitations

- Cutting and pasting an embed inside the editor loses it (paste is plain text).
- Undo slows down over a long session (full history replay).
- Hand-written Markdown: setext headings, lazy continuation, tables and HTML blocks read as paragraph text.
- A whitespace-only paragraph is stored with character references (`&#32;`); leading spaces in a line are kept, but
  other Markdown renderers may show 4+ as code.
- Embed buttons inside the document may wait for super_editor's double-tap timeout before a tap wins.
