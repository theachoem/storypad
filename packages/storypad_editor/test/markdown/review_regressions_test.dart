import 'dart:math';

import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

final _codec = StoryCodec(embeds: testEmbedCodecs);

AttributedText _text(String text, [List<(Attribution, int, int)> spans = const []]) {
  final attributed = AttributedText(text);
  for (final (attribution, start, end) in spans) {
    attributed.addAttribution(attribution, SpanRange(start, end));
  }
  return attributed;
}

void _expectLossless(List<DocumentNode> document, [StoryCodec? codec]) {
  final c = codec ?? _codec;
  final markdown = c.encode(document);
  final decoded = c.decodeNodes(markdown);
  expect(decoded, isEquivalentDocument(document), reason: 'markdown:\n$markdown');
  expect(c.encode(decoded), markdown, reason: 'fixed point');
}

class _ThrowingEmbed extends StoryEmbedCodec<String> {
  const _ThrowingEmbed();

  @override
  String get type => 'thrower';

  @override
  Set<String> get quillKeys => const {'thrower'};

  @override
  Set<String> get htmlTags => const {'sp-thrower'};

  @override
  String? fromQuill(QuillEmbedOp op) => op.value! as String;

  @override
  String? fromHtml(StoryHtmlElement element) => element['src']!;

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('sp-thrower', attributes: {'src': value});
}

void main() {
  group(r'\r, U+2028 and U+2029 in text are kept losslessly', () {
    final cases = <String, DocumentNode>{
      r'bold a\r': ParagraphNode(id: '1', text: _text('a\r', [(boldAttribution, 0, 1)])),
      r'heading a\rb': ParagraphNode(
        id: '1',
        text: _text('a\rb'),
        metadata: {NodeMetadata.blockType: header1Attribution},
      ),
      'done task a U+2028 b': TaskNode(id: '1', text: _text('a b'), isComplete: true),
      'underline a U+2029 b': ParagraphNode(id: '1', text: _text('a b', [(underlineAttribution, 0, 2)])),
      r'code a\rb in a quote': ParagraphNode(
        id: '1',
        text: _text('a\rb', [(codeAttribution, 0, 2)]),
        metadata: {NodeMetadata.blockType: blockquoteAttribution},
      ),
    };
    for (final MapEntry(key: name, value: node) in cases.entries) {
      test(name, () => _expectLossless([node]));
    }

    test('CRLF Markdown and Quill CRLF text read as plain line breaks', () {
      expect(_codec.canonicalize('# T\r\n\r\na\r\n'), '# T\n\na');
      final markdown = _codec.quillToMarkdown([
        {'insert': 'a\r\nb\r\n'},
      ]);
      expect(markdown, 'a\n\nb');
      expect(_codec.canonicalize(markdown), markdown);
    });
  });

  group('HTML lines no embed claims are kept, not turned into text', () {
    final bare = StoryCodec();
    for (final line in [
      '<video controls src="v.mp4"></video>',
      '<time datetime="2024-01-01">2024-01-01</time>',
      '<iframe src="https://x.y"></iframe>',
      '<img src="a b.jpg" data-size="max">',
    ]) {
      test(line, () {
        final node = bare.decodeNodes(line).single as StoryEmbedNode;
        expect(node.value, UnknownHtmlEmbed(line));
        expect(bare.canonicalize('a\n\n$line\n\nb'), 'a\n\n$line\n\nb');
      });
    }

    test('formatting tags and <br> still read as text', () {
      expect(bare.decodeNodes('<p>x</p>').single, isA<ParagraphNode>());
      expect((bare.decodeNodes('<br>').single as ParagraphNode).text.toPlainText(), '\n');
    });
  });

  test('an unknown Quill op is read by an embed registered later', () {
    final older = StoryCodec();
    final markdown = older.quillToMarkdown([
      {
        'insert': {'sticker': 'cat'},
      },
      {'insert': '\n'},
    ]);
    expect(markdown, startsWith('<sp-unknown'));

    final newer = _codec.decodeNodes(markdown).single as StoryEmbedNode;
    expect(newer.type, 'sticker');
    expect(newer.value, 'cat');
  });

  group('a code span inside an HTML-tag format containing the closing tag', () {
    for (final (name, attribution, code) in [
      ('underline', underlineAttribution, 'a</u>b'),
      ('color', const ColorAttribution(Color(0xFF336699)), 'a</span>b'),
      ('superscript', const ScriptAttribution.superscript(), 'x</sup>'),
    ]) {
      test(name, () {
        _expectLossless([
          ParagraphNode(
            id: '1',
            text: _text('$code!', [(attribution, 0, code.length), (codeAttribution, 0, code.length - 1)]),
          ),
        ]);
      });
    }
  });

  group('an embed that throws never aborts reading', () {
    final codec = StoryCodec(embeds: const [_ThrowingEmbed()]);

    test('fromQuill', () {
      final node =
          codec.decodeQuill([
                {
                  'insert': {'thrower': 42},
                },
                {'insert': '\n'},
              ]).single
              as StoryEmbedNode;
      expect(node.value, isA<UnknownQuillEmbed>());
    });

    test('fromHtml', () {
      final node = codec.decodeNodes('<sp-thrower></sp-thrower>').single as StoryEmbedNode;
      expect(node.value, const UnknownHtmlEmbed('<sp-thrower></sp-thrower>'));
    });
  });

  test('conflicting nested markup reads without throwing', () {
    expect(_codec.decodeNodes('[<http://x.y>](x)'), hasLength(1));
    expect(_codec.decodeNodes('<sup><sub>a</sub></sup>'), hasLength(1));
  });

  test('a stock image with an unusual source is a fixed point', () {
    final codec = StoryCodec(embeds: [const StickerEmbedCodec()]);
    final once = codec.canonicalize('![](<a (1).png>)');
    expect(codec.canonicalize(once), once);
  });

  test('trailing whitespace survives tools that trim it', () {
    final node = ParagraphNode(id: '1', text: _text('a  '));
    expect(_codec.encode([node]), 'a&#32;&#32;');
    _expectLossless([node]);
    _expectLossless([
      ParagraphNode(id: '1', text: _text('T  '), metadata: {NodeMetadata.blockType: header2Attribution}),
    ]);
  });

  test('reading hand-written Markdown never throws, and canonicalizing it is idempotent', () {
    const pieces = [
      'a',
      ' ',
      '\n',
      '\n\n',
      '#',
      '-',
      '1.',
      '>',
      '*',
      '**',
      '_',
      '`',
      '```',
      '~~',
      '[',
      '](',
      ')',
      '<',
      '>',
      '&',
      '<u>',
      '</u>',
      '<sup>',
      '</sup>',
      '<sub>',
      '</sub>',
      '<span style="color:#123456">',
      '</span>',
      '<br>',
      '<http://x.y>',
      '![',
      '<div style="text-align:center">',
      '</div>',
      '<sp-x>',
      '&nbsp;',
      '\t',
      '\r',
      ' ',
      '    ',
      '- [ ]',
      '|',
      '===',
      '---',
    ];
    for (var seed = 0; seed < 3000; seed++) {
      final random = Random(seed);
      final input = [for (var i = random.nextInt(25); i > 0; i--) pieces[random.nextInt(pieces.length)]].join();
      final canonical = _codec.canonicalize(input);
      expect(_codec.canonicalize(canonical), canonical, reason: 'seed $seed input: ${input.codeUnits}');
    }
  });
}
