import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:storypad_editor_example/embeds/demo_embeds.dart';

import 'support/fixtures.dart';

/// Each real-shape Quill fixture converts to its checked-in Markdown golden, and the golden is canonical and reads
/// back to the same document the Quill import produced. Regenerate with `UPDATE_GOLDENS=1 flutter test`.
///
/// While stories are still stored as Quill, an edited story is written back through Markdown: each fixture must
/// convert without dropping anything, and come back as equivalent Quill.
void main() {
  final codec = StoryCodec(embeds: demoEmbeds);

  for (final MapEntry(key: name, value: ops) in loadQuillFixtures().entries) {
    group(name, () {
      test('converts to its golden', () {
        final markdown = codec.quillToMarkdown(ops);
        final golden = markdownGolden(name);
        if (updateGoldens) golden.writeAsStringSync('$markdown\n');

        expect('$markdown\n', golden.readAsStringSync());
      });

      test('the golden is canonical and reads back to the imported document', () {
        final golden = markdownGolden(name).readAsStringSync().trimRight();

        expect(codec.canonicalize(golden), golden);
        expect(codec.decodeNodes(golden), isEquivalentDocument(codec.decodeQuill(ops)));
      });

      test('converts without dropping any formatting', () {
        expect(codec.quillImportLosses(ops), isEmpty);
      });

      test('written back as Quill, it is equivalent to the original', () {
        expect(codec.markdownToQuill(codec.quillToMarkdown(ops)), isEquivalentQuill(ops, codec));
      });

      test('the golden converts to Quill and back unchanged', () {
        final golden = markdownGolden(name).readAsStringSync().trimRight();
        expect(codec.quillToMarkdown(codec.markdownToQuill(golden)), golden);
      });
    });
  }
}
