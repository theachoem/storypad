import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

import '../support/test_embeds.dart';

/// A value without `==`, the most likely mistake in an app embed.
class _NoEquality {
  _NoEquality(this.name);

  final String name;
}

class _NoEqualityEmbed extends StoryEmbedCodec<_NoEquality> {
  const _NoEqualityEmbed();

  @override
  String get type => 'no-equality';

  @override
  Set<String> get htmlTags => const {'sp-no-equality'};

  @override
  _NoEquality? fromHtml(StoryHtmlElement element) => _NoEquality(element['name'] ?? '');

  @override
  StoryHtmlElement toHtml(_NoEquality value) => StoryHtmlElement('sp-no-equality', attributes: {'name': value.name});
}

/// Writes a tag it doesn't claim.
class _UnclaimedTagEmbed extends StoryEmbedCodec<String> {
  const _UnclaimedTagEmbed();

  @override
  String get type => 'unclaimed';

  @override
  Set<String> get htmlTags => const {'sp-claimed'};

  @override
  String? fromHtml(StoryHtmlElement element) => element['v'];

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('sp-other', attributes: {'v': value});
}

void main() {
  group('passes for well-behaved embeds', () {
    test('string value', () => expectEmbedRoundTrip(const StickerEmbedCodec(), 'cat'));

    test('values with attributes, alongside other embeds', () {
      for (final value in [
        const GalleryValue(['a.jpg']),
        const GalleryValue(['a.jpg'], alignment: GalleryAlignment.right, size: GallerySize.max),
        const GalleryValue(['a.jpg', 'b c.mp4', 'd"e.jpg'], alignment: GalleryAlignment.center),
      ]) {
        expectEmbedRoundTrip(const GalleryEmbedCodec(), value, otherEmbeds: [const StickerEmbedCodec()]);
      }
    });

    test('unknown values', () {
      expectEmbedRoundTrip<UnknownEmbedValue>(
        const UnknownEmbedCodec(),
        UnknownQuillEmbed({
          'insert': {'x': '1'},
        }),
      );
    });
  });

  group('fails for broken embeds', () {
    test('a value type without ==', () {
      expect(() => expectEmbedRoundTrip(const _NoEqualityEmbed(), _NoEquality('a')), throwsA(isA<TestFailure>()));
    });

    test('a tag missing from htmlTags', () {
      expect(() => expectEmbedRoundTrip(const _UnclaimedTagEmbed(), 'a'), throwsA(isA<TestFailure>()));
    });
  });
}
