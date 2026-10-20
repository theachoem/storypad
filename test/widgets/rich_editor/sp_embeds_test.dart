import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_audio_embed.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_date_embed.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_media_embed.dart';
import 'package:storypad/widgets/rich_editor/sp_embeds.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';

/// Stories are stored as Quill but edited as Markdown: every embed must survive both, and real-shape stories must come
/// back as equivalent Quill with nothing dropped.
void main() {
  List<StoryEmbedCodec> othersThan(StoryEmbedCodec embed) => [
    for (final other in SpEmbeds.all)
      if (other.type != embed.type) other,
  ];

  group('media', () {
    const media = SpMediaEmbed();

    test('a single photo, as the app inserts it (max size)', () {
      EmbedConformance.expectRoundTrip(
        media,
        const SpMediaValue(['images/1.jpg'], size: .max),
        fromQuillOp: {
          'insert': {'media': 'images/1.jpg'},
          'attributes': {'custom-embed-size': 'max'},
        },
        otherEmbeds: othersThan(media),
      );
    });

    test('the legacy image key reads identically', () {
      EmbedConformance.expectRoundTrip(
        media,
        const SpMediaValue(['images/1.jpg', 'images/2.jpg']),
        fromQuillOp: {
          'insert': {'image': 'images/1.jpg|images/2.jpg'},
        },
        otherEmbeds: othersThan(media),
      );
    });

    test('a single video', () {
      EmbedConformance.expectRoundTrip(media, const SpMediaValue(['videos/1.mp4']), otherEmbeds: othersThan(media));
    });

    for (final size in SpEmbedSize.values) {
      for (final alignment in SpEmbedAlignment.values) {
        test('an album mixing photos and videos, size=${size.name} alignment=${alignment.name}', () {
          EmbedConformance.expectRoundTrip(
            media,
            SpMediaValue(
              ['images/1.jpg', 'videos/2.mp4', 'https://example.com/3.jpg'],
              size: size,
              alignment: alignment,
            ),
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
      expect(SpEmbeds.codec.markdownToQuill(SpEmbeds.codec.quillToMarkdown(ops)), ops);
    });
  });

  test('audio', () {
    EmbedConformance.expectRoundTrip(
      const SpAudioEmbed(),
      'audio/1762500783747.m4a',
      fromQuillOp: {
        'insert': {'audio': 'audio/1762500783747.m4a'},
      },
      otherEmbeds: othersThan(const SpAudioEmbed()),
    );
  });

  test('date', () {
    EmbedConformance.expectRoundTrip(
      const SpDateEmbed(),
      DateTime(2023, 6, 15),
      fromQuillOp: {
        'insert': {'date': '[{"insert":"2023-06-15T00:00:00.000"}]'},
      },
      otherEmbeds: othersThan(const SpDateEmbed()),
    );
  });

  group('real-shape stories', () {
    final files = Directory('test/widgets/rich_editor/fixtures').listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final ops = jsonDecode(file.readAsStringSync()) as List<Object?>;

      test('$name converts without dropping anything and comes back as equivalent Quill', () {
        expect(SpEmbeds.codec.quillImportLosses(ops), isEmpty);
        expect(
          SpEmbeds.codec.markdownToQuill(SpEmbeds.codec.quillToMarkdown(ops)),
          QuillEquivalence.matcher(ops, SpEmbeds.codec),
        );
      });
    }
  });
}
