import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

import '../support/random_documents.dart';
import '../support/random_quill.dart';
import '../support/test_embeds.dart';

/// Stories are stored as Quill while edited as Markdown: Quill → Markdown → Quill must keep everything the loss report
/// doesn't flag, and must settle after one trip (so saving an opened story twice never changes it again).
void main() {
  final codec = StoryCodec(embeds: testEmbedCodecs);

  List<Map<String, Object?>> quillRoundTrip(List<Object?> ops) => codec.markdownToQuill(codec.quillToMarkdown(ops));

  group('documents survive a trip through Quill', () {
    for (var seed = 0; seed < 500; seed++) {
      test('seed $seed', () {
        final document = randomDocumentWithEmbeds(Random(seed));
        final ops = codec.encodeQuill(document);
        expect(codec.decodeQuill(ops), isEquivalentDocument(quillNormalized(document)), reason: '$ops');
      });
    }
  });

  group('Quill without flagged losses round-trips equivalently', () {
    for (var seed = 0; seed < 500; seed++) {
      test('seed $seed', () {
        final ops = randomQuillOps(Random(seed), lossless: true);
        expect(codec.quillImportLosses(ops), isEmpty, reason: 'the lossless generator made a lossy line: $ops');
        expect(quillRoundTrip(ops), isEquivalentQuill(ops, codec));
      });
    }
  });

  group('one trip through Quill settles', () {
    for (var seed = 0; seed < 500; seed++) {
      test('seed $seed', () {
        final once = quillRoundTrip(randomQuillOps(Random(seed)));
        expect(quillRoundTrip(once), once);

        final markdown = codec.encode(randomDocumentWithEmbeds(Random(seed)));
        final settled = codec.quillToMarkdown(codec.markdownToQuill(markdown));
        expect(codec.quillToMarkdown(codec.markdownToQuill(settled)), settled);
      });
    }
  });
}
