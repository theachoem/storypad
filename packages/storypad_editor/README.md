# storypad_editor

A controller-centric rich text editor for StoryPad, built on [super_editor](https://github.com/Flutter-Bounty-Hunters/super_editor):

- **Markdown in/out** — Markdown is the only format written (HTML5 tags for formats CommonMark lacks).
- **Quill Delta import** — for migrating existing stories (Delta → Markdown).
- **App-supplied embeds** — each custom embed (media, audio, …) is one object bundling its Quill/Markdown codecs and
  renderer, passed into a single controller that the editor widgets take.

Under active development, not yet ready for use. `example/` is the standalone manual-test app and reference consumer.

## Development

```sh
flutter test --concurrency=1          # package tests
(cd example && flutter test --concurrency=1)
flutter analyze && (cd example && flutter analyze)
```
