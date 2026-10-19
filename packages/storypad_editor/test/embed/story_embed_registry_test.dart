import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:super_editor/super_editor.dart';

import '../support/test_embeds.dart';

class _Embed extends StoryEmbedCodec<String> {
  const _Embed(this.type, {this.quillKeys = const {}, this.htmlTags = const {}});

  @override
  final String type;

  @override
  final Set<String> quillKeys;

  @override
  final Set<String> htmlTags;

  @override
  String? fromHtml(StoryHtmlElement element) => null;

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('sp-x');
}

Matcher _throwsArgumentErrorContaining(String text) =>
    throwsA(isA<ArgumentError>().having((error) => error.message, 'message', contains(text)));

void main() {
  test('registers the app embeds in order, then the unknown embed last', () {
    final registry = StoryEmbedRegistry(testEmbedCodecs);

    expect(registry.embeds.map((embed) => embed.type), ['sticker', 'gallery', 'unknown']);
    expect(registry.embeds.last, same(registry.unknown));
  });

  test('looks embeds up by type, Quill key, HTML tag and node', () {
    final registry = StoryEmbedRegistry(testEmbedCodecs);

    expect(registry.byType('gallery'), isA<GalleryEmbedCodec>());
    expect(registry.byQuillKey('photo'), isA<GalleryEmbedCodec>());
    expect(registry.byHtmlTag('img'), isA<GalleryEmbedCodec>());
    expect(registry.byHtmlTag('sp-unknown'), same(registry.unknown));
    expect(registry.forNode(const StickerEmbedCodec().createNode('cat')), isA<StickerEmbedCodec>());
    expect(registry.forNode(ParagraphNode(id: '1', text: AttributedText())), isNull);
    expect(registry.byQuillKey('mystery'), isNull);
    expect(registry.htmlTags, containsAll(['sp-sticker', 'img', 'sp-gallery', 'sp-unknown']));
  });

  group('rejects', () {
    test('duplicate types', () {
      expect(
        () => StoryEmbedRegistry([const _Embed('a'), const _Embed('a')]),
        _throwsArgumentErrorContaining('both use the type "a"'),
      );
    });

    test('duplicate Quill keys', () {
      expect(
        () => StoryEmbedRegistry([
          const _Embed('a', quillKeys: {'k'}),
          const _Embed('b', quillKeys: {'k'}),
        ]),
        _throwsArgumentErrorContaining('both import the Quill key "k"'),
      );
    });

    test('duplicate HTML tags', () {
      expect(
        () => StoryEmbedRegistry([
          const _Embed('a', htmlTags: {'sp-x'}),
          const _Embed('b', htmlTags: {'sp-x'}),
        ]),
        _throwsArgumentErrorContaining('both claim the HTML tag "<sp-x>"'),
      );
    });

    test('reserved types', () {
      expect(() => StoryEmbedRegistry([const _Embed('paragraph')]), _throwsArgumentErrorContaining('reserved type'));
      expect(() => StoryEmbedRegistry([const _Embed('unknown')]), _throwsArgumentErrorContaining('reserved type'));
    });

    test('reserved tags', () {
      expect(
        () => StoryEmbedRegistry([
          const _Embed('a', htmlTags: {'div'}),
        ]),
        _throwsArgumentErrorContaining('reserved HTML tag "<div>"'),
      );
      expect(
        () => StoryEmbedRegistry([
          const _Embed('a', htmlTags: {'sp-unknown'}),
        ]),
        _throwsArgumentErrorContaining('reserved HTML tag "<sp-unknown>"'),
      );
    });

    test('reserved Quill keys', () {
      for (final key in ['divider', 'sp-markdown']) {
        expect(
          () => StoryEmbedRegistry([
            _Embed('a', quillKeys: {key}),
          ]),
          _throwsArgumentErrorContaining('reserved Quill key "$key"'),
        );
      }
    });

    test('malformed type and tag names', () {
      expect(() => StoryEmbedRegistry([const _Embed('Media')]), _throwsArgumentErrorContaining('invalid type'));
      expect(
        () => StoryEmbedRegistry([
          const _Embed('a', htmlTags: {'sp album'}),
        ]),
        _throwsArgumentErrorContaining('invalid HTML tag'),
      );
    });
  });
}
