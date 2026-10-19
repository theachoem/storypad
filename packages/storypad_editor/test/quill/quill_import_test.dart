import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

final _codec = StoryCodec(embeds: testEmbedCodecs);

List<DocumentNode> _import(List<Object?> ops) => _codec.decodeQuill(ops);

Map<String, Object?> _text(String text, [Map<String, Object?>? attributes]) => {
  'insert': text,
  'attributes': ?attributes,
};

Map<String, Object?> _line([Map<String, Object?>? attributes]) => _text('\n', attributes);

Map<String, Object?> _embed(Map<String, Object?> insert, [Map<String, Object?>? attributes]) => {
  'insert': insert,
  'attributes': ?attributes,
};

String _plain(DocumentNode node) => (node as TextNode).text.toPlainText();

Attribution? _blockType(DocumentNode node) => node.getMetadataValue(NodeMetadata.blockType);

void main() {
  test('paragraphs, and no trailing paragraph from the final newline', () {
    final nodes = _import([_text('a\nb\n')]);
    expect(nodes.map(_plain), ['a', 'b']);
    expect(_codec.quillToMarkdown([_text('a\nb\n')]), 'a\n\nb');
  });

  group('inline formats', () {
    test('flags, colors (both Quill hex forms), background, script, link', () {
      final node =
          _import([
                _text('b', {'bold': true}),
                _text('i', {'italic': true}),
                _text('u', {'underline': true}),
                _text('s', {'strike': true}),
                _text('c', {'code': true}),
                _text('r', {'color': '#FF336699'}),
                _text('g', {'color': '#336699'}),
                _text('h', {'background': '#80FFCC00'}),
                _text('p', {'script': 'super'}),
                _text('l', {'link': 'https://x.y'}),
                _line(),
              ]).first
              as ParagraphNode;

      Set<Attribution> at(int i) => node.text.getAllAttributionsAt(i);
      expect(at(0), {boldAttribution});
      expect(at(1), {italicsAttribution});
      expect(at(2), {underlineAttribution});
      expect(at(3), {strikethroughAttribution});
      expect(at(4), {codeAttribution});
      expect(at(5), {const ColorAttribution(Color(0xFF336699))});
      expect(at(6), {const ColorAttribution(Color(0xFF336699))});
      expect(at(7), {const BackgroundColorAttribution(Color(0x80FFCC00))});
      expect(at(8), {const ScriptAttribution.superscript()});
      expect(at(9), {const LinkAttribution('https://x.y')});
    });

    test('bad values drop just that format (stock formats throw and abort the import)', () {
      final node =
          _import([
                _text('a', {
                  'color': 'red',
                  'background': '#12345',
                  'link': 5,
                  'script': 'x',
                  'bold': false,
                  'size': 'huge',
                }),
                _line(),
              ]).first
              as ParagraphNode;

      expect(node.text.toPlainText(), 'a');
      expect(node.text.getAllAttributionsAt(0), isEmpty);
    });

    test('bold and link together keep both (production\'s converter drops bold)', () {
      expect(
        _codec.quillToMarkdown([
          _text('site', {'bold': true, 'link': 'https://example.com'}),
          _line(),
        ]),
        '[**site**](https://example.com)',
      );
    });
  });

  group('blocks', () {
    test('headings 1–6', () {
      for (var level = 1; level <= 6; level++) {
        final node = _import([
          _text('T'),
          _line({'header': level}),
        ]).first;
        expect(_blockType(node), NamedAttribution('header$level'));
      }
    });

    test('consecutive quote lines and code lines each merge into one block', () {
      final nodes = _import([
        _text('q1'),
        _line({'blockquote': true}),
        _text('q2'),
        _line({'blockquote': true}),
        _text('c1'),
        _line({'code-block': true}),
        _text('c2'),
        _line({'code-block': 'plain'}),
      ]);
      expect(nodes.where((node) => _plain(node).isNotEmpty).map(_plain), ['q1\nq2', 'c1\nc2']);
      expect(_blockType(nodes[0]), blockquoteAttribution);
      expect(_blockType(nodes[1]), codeAttribution);
    });

    test('lists and tasks of all four kinds keep their indent', () {
      final nodes = _import([
        _text('a'),
        _line({'list': 'bullet'}),
        _text('b'),
        _line({'list': 'bullet', 'indent': 1}),
        _text('c'),
        _line({'list': 'ordered', 'indent': 2}),
        _text('d'),
        _line({'list': 'unchecked'}),
        _text('e'),
        _line({'list': 'checked', 'indent': 1}),
        _text('f'),
        _line({'list': 'unchecked', 'indent': 3}),
      ]);

      expect(_codec.encode(nodes), '- a\n    - b\n        1. c\n- [ ] d\n    - [x] e\n            - [ ] f');
    });

    test('Quill-compacted newlines (two empty list items in one op) are two items', () {
      final nodes = _import([
        _text('\n\n', {'list': 'bullet'}),
      ]);
      expect(nodes.whereType<ListItemNode>(), hasLength(2));
    });

    test('indent and alignment together on paragraphs and headings', () {
      final nodes = _import([
        _text('p'),
        _line({'indent': 2, 'align': 'center'}),
        _text('h'),
        _line({'header': 2, 'align': 'right'}),
        _text('j'),
        _line({'align': 'justify'}),
      ]);
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.indent, 2);
      expect(paragraph.getMetadataValue(TextNodeMetadata.textAlign), 'center');
      expect(nodes[1].getMetadataValue(TextNodeMetadata.textAlign), 'right');
      expect(nodes[2].getMetadataValue(TextNodeMetadata.textAlign), 'justify');
    });

    test('alignment on a list item is kept', () {
      final nodes = _import([
        _text('a'),
        _line({'list': 'bullet', 'align': 'center'}),
      ]);
      expect(nodes.first, isA<ListItemNode>());
      expect(nodes.first.getMetadataValue(TextNodeMetadata.textAlign), 'center');
    });

    test('huge and malformed indent values are clamped or ignored', () {
      final nodes = _import([
        _text('a'),
        _line({'list': 'bullet', 'indent': 999999}),
        _text('b'),
        _line({'list': 'unchecked', 'indent': -3}),
        _text('c'),
        _line({'indent': 'x'}),
      ]);
      expect((nodes[0] as ListItemNode).indent, 6);
      expect((nodes[1] as TaskNode).indent, 0);
      expect((nodes[2] as ParagraphNode).indent, 0);
    });
  });

  group('embeds', () {
    test('an embed imports through the embed claiming its key, including a legacy key', () {
      final nodes = _import([
        _embed({'gallery': 'a.jpg|b.jpg'}, {'x-align': 'center', 'x-size': 'max'}),
        _line(),
        _embed({'photo': 'c.jpg'}),
        _line(),
      ]);
      expect(nodes.map((node) => (node as StoryEmbedNode).value), [
        const GalleryValue(['a.jpg', 'b.jpg'], alignment: GalleryAlignment.center, size: GallerySize.max),
        const GalleryValue(['c.jpg']),
      ]);
    });

    test('an unclaimed key is preserved whole by the unknown embed, attributes included', () {
      final node =
          _import([
                _embed({'mystery': 'v'}, {'custom-embed-size': 'max'}),
                _line(),
              ]).single
              as StoryEmbedNode;
      expect(
        node.value,
        UnknownQuillEmbed({
          'insert': {'mystery': 'v'},
          'attributes': {'custom-embed-size': 'max'},
        }),
      );
    });

    test('a value the embed rejects is preserved by the unknown embed', () {
      final node =
          _import([
                _embed({'sticker': ''}),
                _line(),
              ]).single
              as StoryEmbedNode;
      expect(node.value, isA<UnknownQuillEmbed>());
    });

    test('no blank lines are added between embeds and text', () {
      final nodes = _import([
        _text('before\n'),
        _embed({'sticker': 'a'}),
        _line(),
        _embed({'sticker': 'b'}),
        _line({'align': 'center'}),
        _text('after\n'),
      ]);
      expect(nodes.map((node) => NodeDescription(node).describe()), [
        NodeDescription(ParagraphNode(id: 'x', text: AttributedText('before'))).describe(),
        NodeDescription(const StickerEmbedCodec().createNode('a')).describe(),
        NodeDescription(const StickerEmbedCodec().createNode('b')).describe(),
        NodeDescription(ParagraphNode(id: 'x', text: AttributedText('after'))).describe(),
      ]);
    });

    test('a real blank line after an embed is kept', () {
      final nodes = _import([
        _embed({'sticker': 'a'}),
        _line(),
        _line(),
        _text('text\n'),
      ]);
      expect(nodes.map(_plainOrType), ['sticker', '', 'text']);
    });

    test('an embed never swallows an empty list item', () {
      final nodes = _import([
        _line({'list': 'bullet'}),
        _embed({'sticker': 'a'}),
        _line(),
      ]);
      expect(nodes.first, isA<ListItemNode>());
      expect(nodes[1], isA<StoryEmbedNode>());
    });
  });

  test('malformed ops are skipped, never thrown', () {
    final nodes = _import([
      null,
      5,
      'text',
      {'retain': 3},
      {'delete': 1},
      {'insert': 5},
      {'insert': 'ok', 'attributes': 'bad'},
      {'insert': 'fine\n'},
    ]);
    expect(nodes.map(_plain), ['fine']);
  });

  test('Quill → Markdown output is canonical', () {
    final markdown = _codec.quillToMarkdown([
      _text('Title'),
      _line({'header': 1}),
      _text('Hello '),
      _text('world', {'bold': true}),
      _line({'align': 'center'}),
      _embed({'gallery': 'a.jpg'}),
      _line(),
      _text('todo'),
      _line({'list': 'unchecked', 'indent': 1}),
    ]);
    expect(
      markdown,
      '# Title\n\n<div style="text-align:center">\n\nHello **world**\n\n</div>\n\n![](a.jpg)\n\n    - [ ] todo',
    );
    expect(_codec.canonicalize(markdown), markdown);
  });
}

String _plainOrType(DocumentNode node) => node is StoryEmbedNode ? node.type : _plain(node);
