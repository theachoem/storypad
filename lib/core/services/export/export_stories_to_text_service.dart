import 'dart:io';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';

/// Service to export stories to a single plain text file.
/// Stories are concatenated with simple dividers.
class ExportStoriesToTextService {
  /// Exports stories to a single plain text file.
  ///
  /// The file structure:
  /// ```
  /// StoryPad ID: 1735537709471
  /// Title: Story Title 1
  /// Date: 2024-12-20 14:30:45
  /// Tags: tag1, tag2
  /// Event: event_type
  ///
  /// Story content here...
  ///
  /// ###
  ///
  /// StoryPad ID: 1715024221522
  /// Title: Story Title 2
  /// Date: 2024-12-25 09:15:30
  ///
  /// More story content...
  /// ```
  ///
  /// [tagNameGetter] - Optional callback to resolve tag ID to tag name
  /// [eventTypeGetter] - Optional callback to resolve event ID to event type
  static Future<File> call({
    required List<StoryDbModel> stories,
    required File outputFile,
    Future<String?> Function(int tagId)? tagNameGetter,
    Future<String?> Function(int eventId)? eventTypeGetter,
  }) async {
    final buffer = StringBuffer();

    // Filter stories with content first
    final validStories = stories.where((story) {
      final content = story.latestContent ?? story.draftContent;
      return content != null;
    }).toList();

    for (int i = 0; i < validStories.length; i++) {
      final story = validStories[i];
      final content = story.latestContent ?? story.draftContent;

      if (content == null) continue;

      // Add story metadata and content
      await _writeStory(
        buffer,
        story,
        content,
        tagNameGetter: tagNameGetter,
        eventTypeGetter: eventTypeGetter,
      );

      // Add separator between stories (except for last story)
      if (i < validStories.length - 1) {
        buffer.writeln();
        buffer.writeln('###');
        buffer.writeln();
      }
    }

    // Write to file
    await outputFile.create(recursive: true);
    await outputFile.writeAsString(buffer.toString());

    return outputFile;
  }

  static Future<void> _writeStory(
    StringBuffer buffer,
    StoryDbModel story,
    StoryContentDbModel content, {
    Future<String?> Function(int tagId)? tagNameGetter,
    Future<String?> Function(int eventId)? eventTypeGetter,
  }) async {
    // StoryPad ID (for reimport)
    buffer.writeln('StoryPad ID: ${story.id}');

    // Title (only if not empty)
    if (content.title?.trim().isNotEmpty == true) {
      buffer.writeln('Title: ${content.title}');
    }

    // Date
    final date = story.displayPathDate;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
    buffer.writeln('Date: $dateStr');

    // Tags
    if (story.validTags?.isNotEmpty == true && tagNameGetter != null) {
      final tagNames = await Future.wait(
        story.validTags!.map((tagId) => tagNameGetter(tagId)),
      );

      final validTagNames = tagNames.whereType<String>().where((name) => name.isNotEmpty).toList();

      if (validTagNames.isNotEmpty) {
        buffer.writeln('Tags: ${validTagNames.join(', ')}');
      }
    }

    // Event type
    if (story.eventId != null && eventTypeGetter != null) {
      final eventType = await eventTypeGetter(story.eventId!);
      if (eventType != null && eventType.isNotEmpty) {
        buffer.writeln('Event: $eventType');
      }
    }

    // Feeling
    if (story.feeling != null && story.feeling!.isNotEmpty) {
      buffer.writeln('Feeling: ${story.feeling}');
    }

    // Separator line before content
    buffer.writeln();

    // Content (plain text, no formatting)
    if (content.richPages != null && content.richPages!.isNotEmpty) {
      for (int i = 0; i < content.richPages!.length; i++) {
        final page = content.richPages![i];

        // Add page title for multi-page stories
        if (content.richPages!.length > 1) {
          if (page.title?.isNotEmpty == true) {
            buffer.writeln(page.title);
          } else {
            buffer.writeln('Page ${i + 1}');
          }
          buffer.writeln();
        }

        // Add page content (convert from Quill Delta to plain text)
        if (page.body != null) {
          final plainText = QuillDeltaToPlainTextService.call(
            page.body!,
            markdown: false,
            includeMarkdownEmbeds: true,
          ).trim();

          if (plainText.isNotEmpty) {
            buffer.writeln(plainText);
          }
        }

        // Add page separator (except for last page)
        if (i < content.richPages!.length - 1) {
          buffer.writeln();
          buffer.writeln('---');
          buffer.writeln();
        }
      }
    }
  }
}
