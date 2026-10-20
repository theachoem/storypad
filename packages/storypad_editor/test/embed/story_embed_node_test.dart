import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

const _sticker = StickerEmbedCodec();
const _gallery = GalleryEmbedCodec();

void main() {
  test('block type metadata is the embed type', () {
    final node = _sticker.createNode('cat');

    expect(node.getMetadataValue(NodeMetadata.blockType), const NamedAttribution('sticker'));
  });

  test('createNode derives plain text from the value', () {
    expect(_sticker.createNode('cat').plainText, ':cat:');
  });

  test('equality compares id, type and value', () {
    final a = _gallery.createNode(const GalleryValue(['a.jpg']), id: '1');

    expect(a, _gallery.createNode(const GalleryValue(['a.jpg']), id: '1'));
    expect(a, isNot(_gallery.createNode(const GalleryValue(['a.jpg']), id: '2')));
    expect(a, isNot(_gallery.createNode(const GalleryValue(['b.jpg']), id: '1')));
    expect(a.hashCode, _gallery.createNode(const GalleryValue(['a.jpg']), id: '1').hashCode);
  });

  test('equivalent content ignores the id', () {
    final a = _gallery.createNode(const GalleryValue(['a.jpg']), id: '1');

    expect(a.hasEquivalentContent(_gallery.createNode(const GalleryValue(['a.jpg']), id: '2')), isTrue);
    expect(a.hasEquivalentContent(_gallery.createNode(const GalleryValue(['b.jpg']), id: '1')), isFalse);
    expect(a.hasEquivalentContent(ParagraphNode(id: '1', text: AttributedText())), isFalse);
  });

  test('metadata copies keep the value and plain text', () {
    final node = _sticker.createNode('cat');

    final added = node.copyWithAddedMetadata({'extra': true});
    expect(added.value, 'cat');
    expect(added.plainText, ':cat:');
    expect(added.getMetadataValue('extra'), isTrue);
    expect(added.getMetadataValue(NodeMetadata.blockType), const NamedAttribution('sticker'));

    final replaced = node.copyAndReplaceMetadata({});
    expect(replaced.value, 'cat');
    // The block type is re-applied by the constructor, so it can't be lost.
    expect(replaced.getMetadataValue(NodeMetadata.blockType), const NamedAttribution('sticker'));
  });

  test('replaceValue keeps the id and refreshes plain text', () {
    final node = _sticker.createNode('cat', id: 'n1');

    final replaced = _sticker.replaceValue(node, 'dog');
    expect(replaced.id, 'n1');
    expect(replaced.value, 'dog');
    expect(replaced.plainText, ':dog:');
  });

  group('copyContent', () {
    final expanded = UpstreamDownstreamNodeSelection(
      base: UpstreamDownstreamNodePosition.upstream(),
      extent: UpstreamDownstreamNodePosition.downstream(),
    );

    test('returns plain text for an expanded selection', () {
      expect(_sticker.createNode('cat').copyContent(expanded), ':cat:');
    });

    test('returns null for a collapsed selection', () {
      final collapsed = UpstreamDownstreamNodeSelection.collapsed(UpstreamDownstreamNodePosition.upstream());

      expect(_sticker.createNode('cat').copyContent(collapsed), isNull);
    });

    test('returns null (instead of throwing) for a foreign selection type', () {
      expect(_sticker.createNode('cat').copyContent(const TextNodeSelection.collapsed(offset: 0)), isNull);
    });

    test('returns null when there is no plain text', () {
      final node = StoryEmbedNode(id: '1', type: 'sticker', value: 'cat');

      expect(node.copyContent(expanded), isNull);
    });
  });

  test('handles and valueOf identify the owning embed', () {
    final node = _sticker.createNode('cat');

    expect(_sticker.handles(node), isTrue);
    expect(_gallery.handles(node), isFalse);
    expect(_sticker.valueOf(node), 'cat');
  });
}
