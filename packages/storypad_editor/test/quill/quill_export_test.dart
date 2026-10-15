import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

/// Exact shapes of Quill written from documents: what StoryPad's Quill editor would have stored.
void main() {
  final codec = StoryCodec(embeds: testEmbedCodecs);

  List<Map<String, Object?>> quill(String markdown) => codec.markdownToQuill(markdown);

  String id() => Editor.createNodeId();

  test('an empty document is a single newline', () {
    expect(codec.encodeQuill([]), [
      {'insert': '\n'},
    ]);
    expect(quill(''), [
      {'insert': '\n'},
    ]);
  });

  test('plain paragraphs merge into one op, like Quill writes them', () {
    expect(quill('Hello\n\nworld'), [
      {'insert': 'Hello\nworld\n'},
    ]);
  });

  test('empty paragraphs are empty lines, trailing ones included', () {
    expect(quill('a\n\n&nbsp;\n\nb'), [
      {'insert': 'a\n\nb\n'},
    ]);
    expect(
      codec.encodeQuill([
        ParagraphNode(id: id(), text: AttributedText('a')),
        ParagraphNode(id: id(), text: AttributedText()),
      ]),
      [
        {'insert': 'a\n\n'},
      ],
    );
  });

  test('blank lines at the top and bottom survive Quill -> Markdown -> Quill', () {
    const ops = [
      {'insert': '\na\n\n'},
    ];
    final markdown = codec.quillToMarkdown(ops);
    expect(markdown, '&nbsp;\n\na\n\n&nbsp;');
    expect(codec.markdownToQuill(markdown), ops);
    expect(codec.checkQuillPage(ops).isLossless, isTrue);
  });

  test('inline formats', () {
    expect(quill('**b** *i* <u>u</u> ~~s~~ `c` <sup>up</sup><sub>down</sub> [l](https://x.y)'), [
      {
        'insert': 'b',
        'attributes': {'bold': true},
      },
      {'insert': ' '},
      {
        'insert': 'i',
        'attributes': {'italic': true},
      },
      {'insert': ' '},
      {
        'insert': 'u',
        'attributes': {'underline': true},
      },
      {'insert': ' '},
      {
        'insert': 's',
        'attributes': {'strike': true},
      },
      {'insert': ' '},
      {
        'insert': 'c',
        'attributes': {'code': true},
      },
      {'insert': ' '},
      {
        'insert': 'up',
        'attributes': {'script': 'super'},
      },
      {
        'insert': 'down',
        'attributes': {'script': 'sub'},
      },
      {'insert': ' '},
      {
        'insert': 'l',
        'attributes': {'link': 'https://x.y'},
      },
      {'insert': '\n'},
    ]);
  });

  test('colors are lowercase #aarrggbb, alpha first, as the app writes them', () {
    final text = AttributedText('ab')
      ..addAttribution(const ColorAttribution(Color(0xFF336699)), const SpanRange(0, 0))
      ..addAttribution(const BackgroundColorAttribution(Color(0x80FFCC00)), const SpanRange(1, 1));
    expect(codec.encodeQuill([ParagraphNode(id: id(), text: text)]), [
      {
        'insert': 'a',
        'attributes': {'color': '#ff336699'},
      },
      {
        'insert': 'b',
        'attributes': {'background': '#80ffcc00'},
      },
      {'insert': '\n'},
    ]);
    expect(quillColor(const Color(0x0000000A)), '#0000000a');
  });

  test('overlapping formats split into runs', () {
    final ops = quill('**bold *both*** *it*');
    expect(ops, [
      {
        'insert': 'bold ',
        'attributes': {'bold': true},
      },
      {
        'insert': 'both',
        'attributes': {'bold': true, 'italic': true},
      },
      {'insert': ' '},
      {
        'insert': 'it',
        'attributes': {'italic': true},
      },
      {'insert': '\n'},
    ]);
  });

  test('headings, quotes, alignment and indent go on the line break', () {
    expect(quill('# Title\n\n###### Small\n\n> quoted'), [
      {'insert': 'Title'},
      {
        'insert': '\n',
        'attributes': {'header': 1},
      },
      {'insert': 'Small'},
      {
        'insert': '\n',
        'attributes': {'header': 6},
      },
      {'insert': 'quoted'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true},
      },
    ]);

    expect(quill('<div style="text-align:center" data-indent="2">\n\n## Centered\n\n</div>'), [
      {'insert': 'Centered'},
      {
        'insert': '\n',
        'attributes': {'header': 2, 'align': 'center', 'indent': 2},
      },
    ]);
  });

  test('lists and tasks, with indent', () {
    expect(quill('- a\n    1. b\n        - [x] c\n- [ ] d'), [
      {'insert': 'a'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {'insert': 'b'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered', 'indent': 1},
      },
      {'insert': 'c'},
      {
        'insert': '\n',
        'attributes': {'list': 'checked', 'indent': 2},
      },
      {'insert': 'd'},
      {
        'insert': '\n',
        'attributes': {'list': 'unchecked'},
      },
    ]);
  });

  test('aligned list items and tasks', () {
    final ops = quill('<div style="text-align:center">\n\n- a\n- [x] b\n\n</div>');
    expect(ops, [
      {'insert': 'a'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet', 'align': 'center'},
      },
      {'insert': 'b'},
      {
        'insert': '\n',
        'attributes': {'list': 'checked', 'align': 'center'},
      },
    ]);
    expect(codec.quillImportLosses(ops), isEmpty);
    expect(codec.quillToMarkdown(ops), '<div style="text-align:center">\n\n- a\n- [x] b\n\n</div>');
  });

  test('consecutive quote lines merge only when they share their format', () {
    final ops = [
      {'insert': 'a'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true},
      },
      {'insert': 'b'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true},
      },
      {'insert': 'c'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true, 'align': 'center'},
      },
    ];
    expect(codec.quillToMarkdown(ops), '> a<br>b\n\n<div style="text-align:center">\n\n> c\n\n</div>');
    expect(codec.markdownToQuill(codec.quillToMarkdown(ops)), isEquivalentQuill(ops, codec));
  });

  test('empty list items and tasks keep their line', () {
    expect(quill('- \n- [ ] '), [
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {
        'insert': '\n',
        'attributes': {'list': 'unchecked'},
      },
    ]);
  });

  test('a code block is one plain line per line, each marked code-block: true', () {
    expect(quill('```\nline 1\n**not bold**\n```'), [
      {'insert': 'line 1'},
      {
        'insert': '\n',
        'attributes': {'code-block': true},
      },
      {'insert': '**not bold**'},
      {
        'insert': '\n',
        'attributes': {'code-block': true},
      },
    ]);
  });

  test('a line break inside a node ends a Quill line with the same block formats', () {
    expect(quill('> first<br>second'), [
      {'insert': 'first'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true},
      },
      {'insert': 'second'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true},
      },
    ]);
  });

  test('embeds are written through toQuill, each on its own line', () {
    expect(quill('before\n\n<sp-sticker name="cat"></sp-sticker>\n\n<img src="a.jpg" data-align="center">\n\nafter'), [
      {'insert': 'before\n'},
      {
        'insert': {'sticker': 'cat'},
      },
      {'insert': '\n'},
      {
        'insert': {'gallery': 'a.jpg'},
        'attributes': {'x-align': 'center'},
      },
      {'insert': '\nafter\n'},
    ]);
  });

  test('a preserved Quill op is written back verbatim, attributes included', () {
    final op = {
      'insert': {'mystery': 'x'},
      'attributes': {'custom-embed-size': 'max', 'n': 1},
    };
    final ops = [
      op,
      {'insert': '\n'},
    ];
    expect(codec.markdownToQuill(codec.quillToMarkdown(ops)), ops);
  });

  test('a horizontal rule is a divider embed, and reads back as one', () {
    final ops = quill('a\n\n---\n\nb');
    expect(ops, [
      {'insert': 'a\n'},
      {
        'insert': {'divider': 'hr'},
      },
      {'insert': '\nb\n'},
    ]);
    expect(codec.quillToMarkdown(ops), 'a\n\n---\n\nb');
  });

  test('content without a Quill form is written as a Markdown line, and reads back exactly', () {
    const line = '<video-note data-x="1"></video-note>';
    final ops = quill('a\n\n$line');
    expect(ops, [
      {'insert': 'a\n'},
      {
        'insert': {'sp-markdown': line},
      },
      {'insert': '\n'},
    ]);
    expect(codec.quillToMarkdown(ops), 'a\n\n$line');

    // A stock image (no embed claims <img> in this codec).
    final plain = StoryCodec();
    final imageOps = plain.markdownToQuill('![alt](a.jpg)');
    expect(imageOps.first['insert'], {'sp-markdown': '![alt](a.jpg)'});
    expect(plain.quillToMarkdown(imageOps), '![alt](a.jpg)');
  });

  test('a throwing toQuill is reported and the embed is written as Markdown instead', () {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    final throwing = StoryCodec(embeds: [const _ThrowingToQuill()]);
    final ops = throwing.markdownToQuill('<sp-boom></sp-boom>');
    expect(ops.first['insert'], {'sp-markdown': '<sp-boom></sp-boom>'});
    expect(errors, hasLength(1));
    expect(throwing.quillToMarkdown(ops), '<sp-boom></sp-boom>');
  });

  test('the result is JSON-encodable as-is', () {
    final ops = quill('# T\n\n- [x] done\n\n<sp-sticker name="s"></sp-sticker>');
    expect(() => jsonEncode(ops), returnsNormally);
    expect(jsonDecode(jsonEncode(ops)), ops);
  });

  test('round trip through Quill keeps the document', () {
    const markdown =
        '# Title\n\n**bold** and <span style="color:#336699ff">color</span>\n\n- a\n    - b\n- [x] c\n\n'
        '<div style="text-align:right">\n\n> quote\n\n</div>\n\n```\ncode\n```\n\n<sp-sticker name="cat"></sp-sticker>';
    expect(codec.quillToMarkdown(codec.markdownToQuill(markdown)), markdown);
    expect(codec.markdownToQuill(markdown), isEquivalentQuill(codec.markdownToQuill(markdown), codec));
  });
}

class _ThrowingToQuill extends StoryEmbedCodec<String> {
  const _ThrowingToQuill();

  @override
  String get type => 'boom';

  @override
  Set<String> get htmlTags => const {'sp-boom'};

  @override
  String? fromHtml(StoryHtmlElement element) => 'boom';

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('sp-boom');

  @override
  QuillEmbedOp? toQuill(String value) => throw StateError('no');
}
