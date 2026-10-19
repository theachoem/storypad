import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

/// Page titles in Markdown: the title rule, the title heading a Quill page's separate title becomes, and the check
/// that decides whether a converted page may replace its Quill.
void main() {
  final codec = StoryCodec(embeds: testEmbedCodecs);

  group('the title rule', () {
    test('the first block, if it is a heading of any level', () {
      for (var level = 1; level <= 6; level++) {
        expect(codec.pageTitle('${'#' * level} Trip\n\nWent to the beach.'), 'Trip', reason: 'h$level');
      }
    });

    test('only the very first block: a heading after blank lines is content, as the editor sees it', () {
      expect(codec.pageTitle('&nbsp;\n\n&nbsp;\n\n### Trip\n\nbody'), isNull);
    });

    test('no title when the first block is not a heading', () {
      expect(codec.pageTitle('Went to the beach.\n\n### Later'), isNull);
      expect(codec.pageTitle('- item\n\n### Later'), isNull);
      expect(codec.pageTitle('> quote\n\n### Later'), isNull);
      expect(codec.pageTitle(''), isNull);
    });

    test('an empty heading is an empty title', () {
      expect(codec.pageTitle('###\n\nbody'), isNull);
    });

    test('formatting is dropped and the text is trimmed', () {
      expect(codec.pageTitle('### **Big** *day* [at](https://x.y) `sea`'), 'Big day at sea');
    });

    test('the body is what follows the title heading', () {
      List<String> body(String markdown) => [
        for (final node in StoryCodec.pageBodyOf(codec.decodeNodes(markdown))) (node as TextNode).text.toPlainText(),
      ];

      expect(body('### Trip\n\nA\n\nB'), ['A', 'B']);
      expect(body('&nbsp;\n\n### Trip\n\nA'), ['', 'Trip', 'A'], reason: 'no title: everything is body');
      expect(body('###\n\nA'), ['A'], reason: 'an empty leading heading is an empty title, not body');
      expect(body('A\n\n### B'), ['A', 'B'], reason: 'no title: everything is body');
    });
  });

  group('title → heading → title', () {
    const titles = [
      'Trip',
      '#hashtag',
      'Title ##',
      '# not a heading',
      '1. Intro',
      '1) Intro',
      '- dash',
      '+ plus',
      '> quote',
      '*star* and _underscore_',
      '**bold**',
      '`code`',
      '~~strike~~',
      '[link](https://x.y)',
      '<3 <b>html</b> &amp; &nbsp;',
      r'back\slash',
      '![img](a.jpg)',
      '---',
      '===',
      'emoji 🎉 and ខ្មែរ',
    ];

    for (final title in titles) {
      test(title, () {
        final markdown = codec.quillPageToMarkdown(_body, title: title);
        expect(codec.pageTitle(markdown), title);
        expect(codec.checkQuillPage(_body, title: title).isLossless, isTrue);
      });
    }

    test('line breaks are joined and surrounding whitespace trimmed', () {
      expect(PageTitle.normalize('  a\nb\r\nc  '), 'a b c');
      expect(codec.pageTitle(codec.quillPageToMarkdown(_body, title: '  a\nb  ')), 'a b');
      expect(codec.checkQuillPage(_body, title: '  a\nb  ').isLossless, isTrue);
    });

    test('an empty or blank title adds no heading', () {
      for (final title in [null, '', '   ', '\n']) {
        expect(codec.quillPageToMarkdown(_body, title: title), 'Went to the beach.');
      }
    });

    test('the title is written as a level-3 heading, before the body', () {
      expect(codec.quillPageToMarkdown(_body, title: 'Trip'), '### Trip\n\nWent to the beach.');
      expect(
        codec.quillPageToMarkdown(const [
          {'insert': '\n'},
        ], title: 'Trip'),
        '### Trip',
      );
    });
  });

  group('checkQuillPage', () {
    test('a plain page is lossless', () {
      final check = codec.checkQuillPage(_rich, title: 'Trip');
      expect(check.losses, isEmpty);
      expect(check.titleRoundTrips, isTrue);
      expect(check.bodyRoundTrips, isTrue);
      expect(check.isLossless, isTrue);
    });

    test('an untitled page starting with a heading still round-trips (its heading becomes the title)', () {
      const ops = [
        {'insert': 'Day 1'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
        {'insert': 'Went to the beach.\n'},
      ];
      expect(codec.checkQuillPage(ops).isLossless, isTrue);
      expect(codec.pageTitle(codec.quillPageToMarkdown(ops)), 'Day 1');
    });

    test('dropped formatting fails the check', () {
      const ops = [
        {
          'insert': 'big',
          'attributes': {'size': 'large'},
        },
        {'insert': '\n'},
      ];
      final check = codec.checkQuillPage(ops, title: 'Trip');
      expect(check.losses, isNotEmpty);
      expect(check.isLossless, isFalse);
    });

    test('Markdown that does not match the page fails the check', () {
      expect(
        codec.checkQuillPage(_rich, title: 'Trip', markdown: '### Trip\n\nsomething else').bodyRoundTrips,
        isFalse,
      );
      expect(codec.checkQuillPage(_rich, title: 'Trip', markdown: '### Other\n\nWent').titleRoundTrips, isFalse);
      expect(codec.checkQuillPage(_rich, title: 'Trip', markdown: '## Trip\n\nWent').titleRoundTrips, isFalse);
      expect(codec.checkQuillPage(_rich, title: 'Trip', markdown: '### **Trip**\n\nWent').titleRoundTrips, isFalse);
    });

    test('a page reordered by a (hypothetical) converter bug fails, although nothing is reported lost', () {
      const ops = [
        {'insert': 'A\nB\n'},
      ];
      final check = codec.checkQuillPage(ops, markdown: 'B\n\nA');
      expect(check.losses, isEmpty);
      expect(check.isLossless, isFalse);
    });
  });

  test('the codec runs in a background isolate', () async {
    final result = await Isolate.run(() {
      final codec = StoryCodec(embeds: testEmbedCodecs);
      final markdown = codec.quillPageToMarkdown(_rich, title: 'Trip');
      return (
        markdown: markdown,
        title: codec.pageTitle(markdown),
        lossless: codec.checkQuillPage(_rich, title: 'Trip').isLossless,
        plainText: codec.toPlainText(markdown),
      );
    });
    expect(result.title, 'Trip');
    expect(result.lossless, isTrue);
    expect(result.markdown, startsWith('### Trip\n\n'));
    expect(result.plainText, contains('Went'));
  });
}

const _body = [
  {'insert': 'Went to the beach.\n'},
];

const _rich = [
  {'insert': 'Went '},
  {
    'insert': 'swimming',
    'attributes': {'bold': true},
  },
  {'insert': '\nFirst'},
  {
    'insert': '\n',
    'attributes': {'list': 'bullet'},
  },
  {'insert': 'Nested'},
  {
    'insert': '\n',
    'attributes': {'list': 'ordered', 'indent': 1},
  },
  {'insert': 'Done'},
  {
    'insert': '\n',
    'attributes': {'list': 'checked'},
  },
  {'insert': 'Quote'},
  {
    'insert': '\n',
    'attributes': {'blockquote': true},
  },
  {
    'insert': {'sticker': 'cat'},
  },
  {'insert': '\nCentered'},
  {
    'insert': '\n',
    'attributes': {'align': 'center'},
  },
];
