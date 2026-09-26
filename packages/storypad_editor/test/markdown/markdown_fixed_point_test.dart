import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

import '../support/random_documents.dart';
import '../support/test_embeds.dart';

/// The storage-format guarantees, which the app's dirty tracking depends on:
///
/// 1. `decode(encode(document))` is equivalent to the document (nothing is lost).
/// 2. `encode(decode(encode(document))) == encode(document)` (opening and saving an untouched story changes nothing).
/// 3. Canonicalizing hand-written Markdown is idempotent.
void main() {
  final codec = StoryCodec();

  group('random documents', () {
    for (var seed = 0; seed < 1000; seed++) {
      test('seed $seed', () {
        final document = randomTextDocument(Random(seed));

        final markdown = codec.encode(document);
        final decoded = codec.decodeNodes(markdown);

        expect(decoded, isEquivalentDocument(document), reason: 'markdown:\n$markdown');
        expect(codec.encode(decoded), markdown, reason: 'fixed point');
      });
    }
  });

  group('random documents with embeds', () {
    final embedCodec = StoryCodec(embeds: testEmbedCodecs);

    for (var seed = 0; seed < 1000; seed++) {
      test('seed $seed', () {
        final document = randomDocumentWithEmbeds(Random(seed));

        final markdown = embedCodec.encode(document);
        final decoded = embedCodec.decodeNodes(markdown);

        expect(decoded, isEquivalentDocument(document), reason: 'markdown:\n$markdown');
        expect(embedCodec.encode(decoded), markdown, reason: 'fixed point');
      });
    }
  });

  group('hand-written Markdown canonicalizes idempotently', () {
    const corpus = {
      'soft line breaks': 'Line one\nline two',
      'two-space hard break': 'a  \nb',
      'loose list': '- a\n\n- b\n\n\n- c',
      'setext-looking lines': 'Title\n=====',
      'closing hashes': '# Title #',
      'nested quote markers': '> > nested',
      'list with 2-space nesting': '* a\n  * b\n    * c',
      'task list': '- [ ] todo\n- [x] done',
      'mixed': '# H\n\nText with *em*, **strong**, `code` and [a link](https://x.y).\n\n---\n\n1. one\n2. two',
      'html-ish text': '<p>not a known block</p>',
      'unclosed div': '<div style="text-align:center">\n\nx',
      'entities': 'AT&amp;T &lt;3 &nbsp;',
      'blank lines everywhere': '\n\n\na\n\n\n\nb\n\n\n',
    };

    for (final MapEntry(key: name, value: markdown) in corpus.entries) {
      test(name, () {
        final canonical = codec.canonicalize(markdown);
        expect(codec.canonicalize(canonical), canonical, reason: 'canonical:\n$canonical');
      });
    }
  });
}
