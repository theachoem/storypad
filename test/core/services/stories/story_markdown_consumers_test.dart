import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/adapters/objectbox/helpers/story_content_helper.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/generate_body_plain_text_service.dart';
import 'package:storypad/core/services/stories/story_content_embed_extractor.dart';
import 'package:storypad/core/services/stories/story_extract_assets_from_pages_service.dart';
import 'package:storypad/core/services/stories/story_has_data_written_service.dart';

/// Everything that reads stories gives the same answer for a page stored as Markdown as it did for the Quill page it
/// was converted from.
void main() {
  final legacyPages = [
    StoryPageDbModel.legacy(
      id: 1,
      title: 'Trip',
      body: [
        {'insert': 'Went '},
        {
          'insert': 'swimming',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
        {
          'insert': {'media': 'images/101.jpg|videos/102.mp4'},
          'attributes': {'custom-embed-size': 'max'},
        },
        {'insert': '\n'},
        {
          'insert': {'audio': 'audio/103.m4a'},
        },
        {'insert': '\nDone'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'},
        },
      ],
    ),
    StoryPageDbModel.legacy(
      id: 2,
      title: 'Day two',
      body: [
        {
          'insert': {'image': 'images/104.jpg'},
        },
        {'insert': '\nRain.\n'},
      ],
    ),
  ];
  final markdownPages = [for (final page in legacyPages) page.toMarkdownPage()];

  StoryContentDbModel contentOf(List<StoryPageDbModel> pages) =>
      StoryContentDbModel.create().copyWith(title: pages.first.title, richPages: pages);

  test('asset ids', () {
    expect(StoryExtractAssetsFromPagesService.call(markdownPages), {101, 102, 103, 104});
    expect(
      StoryExtractAssetsFromPagesService.call(markdownPages),
      StoryExtractAssetsFromPagesService.call(legacyPages),
    );
    expect(StoryContentEmbedExtractor.assetIds(contentOf(markdownPages)), {101, 102, 103, 104});
  });

  test('embed sources: photos, videos, audio', () {
    final legacy = contentOf(legacyPages);
    final markdown = contentOf(markdownPages);
    expect(StoryContentEmbedExtractor.photos(markdown), ['images/101.jpg', 'images/104.jpg']);
    expect(StoryContentEmbedExtractor.photos(markdown), StoryContentEmbedExtractor.photos(legacy));
    expect(StoryContentEmbedExtractor.videos(markdown), StoryContentEmbedExtractor.videos(legacy));
    expect(StoryContentEmbedExtractor.audio(markdown), StoryContentEmbedExtractor.audio(legacy));
  });

  test('preview text and counts', () {
    final legacy = GenerateBodyPlainTextService.call(legacyPages)!;
    final markdown = GenerateBodyPlainTextService.call(markdownPages)!;
    expect(markdown.plainText, legacy.plainText);
    expect(
      markdown.richPagesWithCounts.map((page) => (page.wordCount, page.characterCount)),
      legacy.richPagesWithCounts.map((page) => (page.wordCount, page.characterCount)),
    );
  });

  test('preview text and counts in a background isolate (as opening a story computes them)', () async {
    final expected = GenerateBodyPlainTextService.call(markdownPages)!.plainText;
    final pagesJson = [for (final page in markdownPages) page.toJson()];
    final plainText = await Isolate.run(
      () => GenerateBodyPlainTextService.call(pagesJson.map(StoryPageDbModel.fromJson).toList())!.plainText,
    );
    expect(plainText, expected);
  });

  test('whether anything is written', () {
    expect(StoryHasDataWrittenService.callByContent(contentOf(markdownPages)), isTrue);
    expect(StoryHasDataWrittenService.callByContent(contentOf([StoryPageDbModel.create(id: 1)])), isFalse);
    expect(StoryHasDataWrittenService.callByContent(contentOf([StoryPageDbModel.create(id: 1, title: 'A')])), isTrue);
  });

  test('legacy asset links stay findable in the stored content (the relative-path migration replaces them)', () {
    final page = StoryPageDbModel.legacy(
      id: 1,
      body: [
        {
          'insert': {'image': 'storypad://assets/7'},
        },
        {'insert': '\n'},
      ],
    ).toMarkdownPage();
    final stored = StoryContentHelper.contentToString(contentOf([page]));
    expect(stored, contains('storypad://assets/7'));

    final migrated = StoryContentHelper.stringToContent(stored.replaceAll('storypad://assets/7', 'images/7.jpg'));
    expect(StoryContentEmbedExtractor.photos(migrated), ['images/7.jpg']);
  });
}
