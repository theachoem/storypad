# Fixtures

- `quill/` — real-shape Quill Delta stories (anonymized structural copies of production data), carried over from
  `super_editor_experiment/test/fixtures/`.
- `markdown/` — what each converts to. Regenerate with `UPDATE_GOLDENS=1 flutter test test/real_shape_golden_test.dart`
  and review the diff.

## Expected differences from the experiment's goldens

The experiment's goldens (`super_editor_experiment/test/fixtures/markdown_golden/`) used the earlier format. These
differences are intentional:

1. **Lists**: `-` markers at column 0 and 4 spaces per nesting level (was `  * ` with a 2-space base, which doesn't
   nest correctly under `1.` markers in CommonMark renderers). List items of different kinds are no longer separated by
   blank lines — each line is an item on its own.
2. **`<sp-unknown data-op>`** encodes the whole Quill op (`{"insert": …, "attributes": …}`), not just the insert map,
   so an unknown embed's attributes survive too.
3. **A blank line always follows an embed.** The experiment only got one by accident (from the empty paragraph
   super_editor's Quill parser inserts after every embed); without it, a caption right after an album is absorbed into
   the HTML block by CommonMark renderers.
4. Golden files end with a newline (file convention only; the Markdown itself has no trailing newline).
