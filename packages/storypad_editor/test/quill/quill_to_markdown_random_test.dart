import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';

import '../support/random_documents.dart';
import '../support/test_embeds.dart';

/// Random Quill documents (any mix of inline formats, block attributes, embeds and junk) must convert without
/// throwing, to Markdown that is already canonical -- so opening a migrated story never reports a change.
void main() {
  final codec = StoryCodec(embeds: testEmbedCodecs);

  const inline = <Map<String, Object?>>[
    {'bold': true},
    {'italic': true},
    {'underline': true, 'strike': true},
    {'code': true},
    {'color': '#FF336699'},
    {'background': '#80FFCC00', 'italic': true},
    {'link': 'https://example.com/x y'},
    {'script': 'sub'},
    {'size': 'large', 'font': 'serif'},
    {'color': 'not a color'},
  ];
  const block = <Map<String, Object?>>[
    {'header': 1},
    {'header': 3, 'align': 'center'},
    {'blockquote': true},
    {'blockquote': true, 'indent': 1},
    {'code-block': true},
    {'list': 'bullet'},
    {'list': 'ordered', 'indent': 2},
    {'list': 'checked', 'indent': 1},
    {'list': 'unchecked', 'align': 'right'},
    {'align': 'justify', 'indent': 3},
    {'direction': 'rtl'},
  ];

  List<Object?> randomOps(Random random) {
    final ops = <Object?>[];
    for (var line = 1 + random.nextInt(10); line > 0; line--) {
      switch (random.nextInt(6)) {
        case 0:
          ops.add({
            'insert': switch (random.nextInt(4)) {
              0 => {'sticker': randomString(random, lineBreaks: false)},
              1 => {'gallery': 'a.jpg|b c.jpg'},
              2 => {'photo': 'x.jpg'},
              _ => {'mystery-${random.nextInt(3)}': randomString(random)},
            },
            if (random.nextBool()) 'attributes': {'x-align': 'center', 'custom-embed-size': 'max'},
          });
        default:
          for (var run = random.nextInt(4); run > 0; run--) {
            ops.add({
              'insert': randomString(random, lineBreaks: false),
              if (random.nextBool()) 'attributes': inline[random.nextInt(inline.length)],
            });
          }
      }
      ops.add({'insert': '\n', if (random.nextInt(3) == 0) 'attributes': block[random.nextInt(block.length)]});
    }
    return ops;
  }

  for (var seed = 0; seed < 1000; seed++) {
    test('seed $seed', () {
      final markdown = codec.quillToMarkdown(randomOps(Random(seed)));
      expect(codec.canonicalize(markdown), markdown);
    });
  }
}
