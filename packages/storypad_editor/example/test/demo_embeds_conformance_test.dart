import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:storypad_editor_example/embeds/demo_embeds.dart';

/// The demo embeds, checked the way StoryPad's app would check its own.
void main() {
  const others = demoEmbeds;

  group('media', () {
    const media = MediaEmbed();
    List<StoryEmbedCodec> othersThan(StoryEmbedCodec embed) => others.where((e) => e.type != embed.type).toList();

    test('a single photo', () {
      expectEmbedRoundTrip(
        media,
        const MediaValue(['images/a.jpg']),
        fromQuillOp: {
          'insert': {'media': 'images/a.jpg'},
        },
        otherEmbeds: othersThan(media),
      );
    });

    test('the legacy image key imports identically', () {
      expectEmbedRoundTrip(
        media,
        const MediaValue(['images/a.jpg'], size: EmbedSize.max),
        fromQuillOp: {
          'insert': {'image': 'images/a.jpg'},
          'attributes': {'custom-embed-size': 'max'},
        },
        otherEmbeds: othersThan(media),
      );
    });

    test('a single video', () {
      expectEmbedRoundTrip(media, const MediaValue(['videos/a.mp4']), otherEmbeds: othersThan(media));
    });

    for (final size in EmbedSize.values) {
      for (final alignment in EmbedAlignment.values) {
        test('an album, size=${size.name} alignment=${alignment.name}', () {
          expectEmbedRoundTrip(
            media,
            MediaValue(['images/a.jpg', 'videos/b.mp4'], size: size, alignment: alignment),
            fromQuillOp: {
              'insert': {'media': 'images/a.jpg|videos/b.mp4'},
              'attributes': {
                'custom-embed-size': size == EmbedSize.max ? 'max' : 'default',
                if (alignment != EmbedAlignment.none) 'custom-embed-alignment': alignment.name,
              },
            },
            otherEmbeds: othersThan(media),
          );
        });
      }
    }

    test('an empty value is rejected, so the unknown embed preserves it', () {
      final node = StoryCodec(embeds: demoEmbeds).decodeQuill([
        {
          'insert': {'media': ''},
        },
        {'insert': '\n'},
      ]).single;
      expect((node as StoryEmbedNode).value, isA<UnknownQuillEmbed>());
    });
  });

  test('audio', () {
    expectEmbedRoundTrip(
      const AudioEmbed(),
      'audio/1.m4a',
      fromQuillOp: {
        'insert': {'audio': 'audio/1.m4a'},
      },
      otherEmbeds: [const MediaEmbed(), const DateEmbed()],
    );
  });

  group('date', () {
    test('well-formed', () {
      expectEmbedRoundTrip(
        const DateEmbed(),
        DateTime(2024, 1, 1),
        fromQuillOp: {
          'insert': {'date': r'[{"insert":"2024-01-01T00:00:00.000\n"}]'},
        },
        otherEmbeds: [const MediaEmbed(), const AudioEmbed()],
      );
    });

    test('malformed values are preserved by the unknown embed, not dropped', () {
      final codec = StoryCodec(embeds: demoEmbeds);
      final markdown = codec.quillToMarkdown([
        {
          'insert': {'date': 'not valid json'},
        },
        {'insert': '\n'},
      ]);
      expect(markdown, startsWith('<sp-unknown data-op="'));
      expect((codec.decodeNodes(markdown).single as StoryEmbedNode).value, isA<UnknownQuillEmbed>());
    });
  });
}
