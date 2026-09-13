import 'dart:io';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';

/// Service to export stories to a single CSV file, one row per story.
class ExportStoriesToCsvService {
  static const List<String> header = [
    'id',
    'year',
    'month',
    'day',
    'title',
    'body',
    'tags',
    'starred',
    'pinned',
  ];

  /// [tagNameGetter] - Optional callback to resolve tag ID to tag name
  static Future<File> call({
    required List<StoryDbModel> stories,
    required File outputFile,
    Future<String?> Function(int tagId)? tagNameGetter,
  }) async {
    final validStories = stories.where((story) {
      final content = story.latestContent ?? story.draftContent;
      return content != null;
    }).toList();

    final rows = <List<dynamic>>[header];

    for (final story in validStories) {
      final content = story.latestContent ?? story.draftContent;
      if (content == null) continue;

      rows.add(await _buildRow(story, content, tagNameGetter: tagNameGetter));
    }

    await outputFile.create(recursive: true);
    await outputFile.writeAsString(csv_pkg.csv.encode(rows));

    return outputFile;
  }

  static Future<List<dynamic>> _buildRow(
    StoryDbModel story,
    StoryContentDbModel content, {
    Future<String?> Function(int tagId)? tagNameGetter,
  }) async {
    final date = story.displayPathDate;

    String tagsCell = '';
    if (story.validTags?.isNotEmpty == true && tagNameGetter != null) {
      final tagNames = await Future.wait(
        story.validTags!.map((tagId) => tagNameGetter(tagId)),
      );

      final validTagNames = tagNames.whereType<String>().where((name) => name.isNotEmpty).toList();
      tagsCell = validTagNames.join('|');
    }

    return [
      story.id,
      date.year,
      date.month,
      date.day,
      content.title ?? '',
      _buildBody(content),
      tagsCell,
      story.starred == true ? '1' : '0',
      story.pinned == true ? '1' : '0',
    ];
  }

  static String _buildBody(StoryContentDbModel content) {
    if (content.richPages == null || content.richPages!.isEmpty) return '';

    final texts = <String>[];
    for (final page in content.richPages!) {
      if (page.body == null) continue;

      final plainText = QuillDeltaToPlainTextService.call(
        page.body!,
        markdown: false,
        includeMarkdownEmbeds: true,
      ).trim();

      if (plainText.isNotEmpty) texts.add(plainText);
    }

    return texts.join('\n\n');
  }
}
