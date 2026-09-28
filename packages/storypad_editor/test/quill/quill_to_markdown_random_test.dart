import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../support/random_quill.dart';
import '../support/test_embeds.dart';

/// Random Quill documents (any mix of inline formats, block attributes, embeds and junk) must convert without
/// throwing, to Markdown that is already canonical -- so opening a migrated story never reports a change.
void main() {
  final codec = StoryCodec(embeds: testEmbedCodecs);

  for (var seed = 0; seed < 1000; seed++) {
    test('seed $seed', () {
      final markdown = codec.quillToMarkdown(randomQuillOps(Random(seed)));
      expect(codec.canonicalize(markdown), markdown);
    });
  }
}
