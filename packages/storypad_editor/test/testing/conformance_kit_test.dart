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

/// Imports Quill but can't write it back.
class _NoToQuillEmbed extends StoryEmbedCodec<String> {
  const _NoToQuillEmbed();

  @override
  String get type => 'one-way';

  @override
  Set<String> get quillKeys => const {'one-way'};

  @override
  Set<String> get htmlTags => const {'sp-one-way'};

  @override
  String? fromQuill(QuillEmbedOp op) => '${op.value}';

  @override
  String? fromHtml(StoryHtmlElement element) => element['v'];

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('sp-one-way', attributes: {'v': value});
}

/// Writes Quill that doesn't import back as the same value.
class _LossyToQuillEmbed extends _NoToQuillEmbed {
  const _LossyToQuillEmbed();

  @override
  QuillEmbedOp toQuill(String value) => QuillEmbedOp.of('one-way', value.toUpperCase());
}

void main() {
  group('passes for well-behaved embeds', () {
    test('string value', () {
      EmbedConformance.expectRoundTrip(
        const StickerEmbedCodec(),
        'cat',
        fromQuillOp: {
          'insert': {'sticker': 'cat'},
        },
      );
    });

    test('Quill import with typed attributes, through a legacy key', () {
      EmbedConformance.expectRoundTrip(
        const GalleryEmbedCodec(),
        const GalleryValue(['a.jpg', 'b.jpg'], alignment: GalleryAlignment.left, size: GallerySize.max),
        fromQuillOp: {
          'insert': {'photo': 'a.jpg|b.jpg'},
          'attributes': {'x-align': 'left', 'x-size': 'max'},
        },
      );
    });

    test('values with attributes, alongside other embeds', () {
      for (final value in [
        const GalleryValue(['a.jpg']),
        const GalleryValue(['a.jpg'], alignment: GalleryAlignment.right, size: GallerySize.max),
        const GalleryValue(['a.jpg', 'b c.mp4', 'd"e.jpg'], alignment: GalleryAlignment.center),
      ]) {
        EmbedConformance.expectRoundTrip(const GalleryEmbedCodec(), value, otherEmbeds: [const StickerEmbedCodec()]);
      }
    });

    test('unknown values', () {
      EmbedConformance.expectRoundTrip<UnknownEmbedValue>(
        const UnknownEmbedCodec(),
        UnknownQuillEmbed({
          'insert': {'x': '1'},
        }),
      );
    });
  });

  group('fails for broken embeds', () {
    test('a value type without ==', () {
      expect(
        () => EmbedConformance.expectRoundTrip(const _NoEqualityEmbed(), _NoEquality('a')),
        throwsA(isA<TestFailure>()),
      );
    });

    test('a Quill op that imports as a different value', () {
      expect(
        () => EmbedConformance.expectRoundTrip(
          const StickerEmbedCodec(),
          'cat',
          fromQuillOp: {
            'insert': {'sticker': 'dog'},
          },
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('an embed importing Quill without toQuill', () {
      expect(() => EmbedConformance.expectRoundTrip(const _NoToQuillEmbed(), 'a'), throwsA(isA<TestFailure>()));
    });

    test('a toQuill that imports back as a different value', () {
      expect(() => EmbedConformance.expectRoundTrip(const _LossyToQuillEmbed(), 'a'), throwsA(isA<TestFailure>()));
    });

    test('a tag missing from htmlTags', () {
      expect(() => EmbedConformance.expectRoundTrip(const _UnclaimedTagEmbed(), 'a'), throwsA(isA<TestFailure>()));
    });
  });
}
