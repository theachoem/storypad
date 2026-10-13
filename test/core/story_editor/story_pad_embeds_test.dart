import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/story_editor/embeds/audio_embed.dart';
import 'package:storypad/core/story_editor/embeds/date_embed.dart';
import 'package:storypad/core/story_editor/embeds/embed_attributes.dart';
import 'package:storypad/core/story_editor/embeds/media_embed.dart';
import 'package:storypad/core/story_editor/story_pad_embeds.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

/// Stories are stored as Quill but edited as Markdown: every embed must survive both, and real-shape stories must come
/// back as equivalent Quill with nothing dropped.
void main() {
  List<StoryEmbedCodec> othersThan(StoryEmbedCodec embed) => [
    for (final other in storyPadEmbeds)
      if (other.type != embed.type) other,
  ];

  group('media', () {
    const media = MediaEmbed();

    test('a single photo, as the app inserts it (max size)', () {
      expectEmbedRoundTrip(
        media,
        const MediaValue(['images/1.jpg'], size: .max),
        fromQuillOp: {
          'insert': {'media': 'images/1.jpg'},
          'attributes': {'custom-embed-size': 'max'},
        },
        otherEmbeds: othersThan(media),
      );
    });

    test('the legacy image key reads identically', () {
      expectEmbedRoundTrip(
        media,
        const MediaValue(['images/1.jpg', 'images/2.jpg']),
        fromQuillOp: {
          'insert': {'image': 'images/1.jpg|images/2.jpg'},
        },
        otherEmbeds: othersThan(media),
      );
    });

    test('a single video', () {
      expectEmbedRoundTrip(media, const MediaValue(['videos/1.mp4']), otherEmbeds: othersThan(media));
    });

    for (final size in EmbedSize.values) {
      for (final alignment in EmbedAlignment.values) {
        test('an album mixing photos and videos, size=${size.name} alignment=${alignment.name}', () {
          expectEmbedRoundTrip(
            media,
            MediaValue(['images/1.jpg', 'videos/2.mp4', 'https://example.com/3.jpg'], size: size, alignment: alignment),
            fromQuillOp: {
              'insert': {'media': 'images/1.jpg|videos/2.mp4|https://example.com/3.jpg'},
              'attributes': {
                'custom-embed-size': size == .max ? 'max' : 'default',
                if (alignment != .none) 'custom-embed-alignment': alignment.name,
              },
            },
            otherEmbeds: othersThan(media),
          );
        });
      }
    }

    test('an empty value is rejected, so the unknown embed keeps it', () {
      final ops = [
        {
          'insert': {'media': ''},
        },
        {'insert': '\n'},
      ];
      expect(storyPadCodec.markdownToQuill(storyPadCodec.quillToMarkdown(ops)), ops);
    });
  });

  test('audio', () {
    expectEmbedRoundTrip(
      const AudioEmbed(),
      'audio/1762500783747.m4a',
      fromQuillOp: {
        'insert': {'audio': 'audio/1762500783747.m4a'},
      },
      otherEmbeds: othersThan(const AudioEmbed()),
    );
  });

  test('date', () {
    expectEmbedRoundTrip(
      const DateEmbed(),
      DateTime(2023, 6, 15),
      fromQuillOp: {
        'insert': {'date': '[{"insert":"2023-06-15T00:00:00.000"}]'},
      },
      otherEmbeds: othersThan(const DateEmbed()),
    );
  });

  group('real-shape stories', () {
    final files = Directory('test/core/story_editor/fixtures').listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final ops = jsonDecode(file.readAsStringSync()) as List<Object?>;

      test('$name converts without dropping anything and comes back as equivalent Quill', () {
        expect(storyPadCodec.quillImportLosses(ops), isEmpty);
        expect(
          storyPadCodec.markdownToQuill(storyPadCodec.quillToMarkdown(ops)),
          isEquivalentQuill(ops, storyPadCodec),
        );
      });
    }
  });
}
