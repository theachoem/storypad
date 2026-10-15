import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

final _codec = StoryCodec(embeds: testEmbedCodecs);

const _sticker = StickerEmbedCodec();
const _gallery = GalleryEmbedCodec();

T _single<T extends DocumentNode>(String markdown, [StoryCodec? codec]) {
  final nodes = (codec ?? _codec).decodeNodes(markdown);
  expect(nodes, hasLength(1), reason: 'nodes: ${nodes.map(describeNode)}');
  return nodes.single as T;
}

void main() {
  group('writing', () {
    test('an embed is one line of HTML from its codec', () {
      expect(_codec.encode([_sticker.createNode('cat')]), '<sp-sticker name="cat"></sp-sticker>');
    });

    test('an <img> with only src is written as a Markdown image', () {
      expect(
        _codec.encode([
          _gallery.createNode(const GalleryValue(['images/a.jpg'])),
        ]),
        '![](images/a.jpg)',
      );
    });

    test('an <img> with other attributes stays HTML', () {
      expect(
        _codec.encode([
          _gallery.createNode(const GalleryValue(['a.jpg'], alignment: GalleryAlignment.center)),
        ]),
        '<img src="a.jpg" data-align="center">',
      );
    });

    test('an <img> whose src would not read back exactly stays HTML', () {
      expect(
        _codec.encode([
          _gallery.createNode(const GalleryValue(['a b.jpg'])),
        ]),
        '<img src="a b.jpg">',
      );
    });

    test('a container with children', () {
      expect(
        _codec.encode([
          _gallery.createNode(const GalleryValue(['a.jpg', 'b.jpg'], size: GallerySize.max)),
        ]),
        '<sp-gallery data-size="max"><img src="a.jpg"><img src="b.jpg"></sp-gallery>',
      );
    });

    test('embeds are separated from neighbouring blocks by blank lines', () {
      expect(
        _codec.encode([
          ParagraphNode(id: 'p', text: AttributedText('a')),
          _sticker.createNode('x'),
          _sticker.createNode('y'),
          ListItemNode.unordered(id: 'l', text: AttributedText('b')),
        ]),
        'a\n\n<sp-sticker name="x"></sp-sticker>\n\n<sp-sticker name="y"></sp-sticker>\n\n- b',
      );
    });

    test('an embed of an unregistered type is a configuration error', () {
      expect(() => StoryCodec().encode([_sticker.createNode('cat')]), throwsStateError);
    });
  });

  group('reading', () {
    test('an embed line reads through its codec', () {
      final node = _single<StoryEmbedNode>('<sp-sticker name="cat"></sp-sticker>');
      expect(node.type, 'sticker');
      expect(node.value, 'cat');
      expect(node.plainText, ':cat:');
    });

    test('a bare Markdown image reads through the embed claiming img', () {
      expect(_single<StoryEmbedNode>('![](images/a.jpg)').value, const GalleryValue(['images/a.jpg']));
    });

    test('with no embed claiming img, a Markdown image is a stock ImageNode and writes back', () {
      final codec = StoryCodec(embeds: [_sticker]);
      final node = _single<ImageNode>('![alt](x.png)', codec);
      expect(node.imageUrl, 'x.png');
      expect(node.altText, 'alt');
      expect(codec.encode([node]), '![alt](x.png)');
    });

    test('a line an embed rejects is kept verbatim as unknown', () {
      const line = '<sp-sticker></sp-sticker>';
      final node = _single<StoryEmbedNode>(line);
      expect(node.value, const UnknownHtmlEmbed(line));
      expect(_codec.encode([node]), line);
    });

    test('an unregistered sp- line is kept verbatim (forward compatibility)', () {
      const line = '<sp-poll data-q="Lunch?"><li>a</li></sp-poll>';
      final node = _single<StoryEmbedNode>(line);
      expect(node.value, const UnknownHtmlEmbed(line));
      expect(_codec.canonicalize('a\n\n$line\n\nb'), 'a\n\n$line\n\nb');
    });

    test('sp-unknown round-trips a Quill op; a malformed one is kept verbatim', () {
      final value = UnknownQuillEmbed({
        'insert': {'mystery': 1},
      });
      final markdown = _codec.encode([const UnknownEmbedCodec().createNode(value)]);
      expect(_single<StoryEmbedNode>(markdown).value, value);

      const malformed = '<sp-unknown data-op="%%%"></sp-unknown>';
      expect(_single<StoryEmbedNode>(malformed).value, const UnknownHtmlEmbed(malformed));
    });

    test('other HTML is paragraph text', () {
      expect(_single<ParagraphNode>('<p>x</p>').text.toPlainText(), '<p>x</p>');
    });

    test('an embed tag followed by text on the same line is text, not an embed', () {
      expect(_single<ParagraphNode>('<img src="a.jpg"> caption').text.toPlainText(), '<img src="a.jpg"> caption');
    });

    test('case-insensitive tags', () {
      expect(_single<StoryEmbedNode>('<SP-STICKER NAME="cat"></SP-STICKER>').value, 'cat');
    });
  });

  test('plain text', () {
    final markdown = _codec.encode([
      ParagraphNode(id: 'p', text: AttributedText('Hello')..addAttribution(boldAttribution, const SpanRange(0, 4))),
      _sticker.createNode('cat'),
      TaskNode(id: 't', text: AttributedText('todo'), isComplete: false),
    ]);
    expect(_codec.toPlainText(markdown), 'Hello\n:cat:\ntodo');
  });
}
