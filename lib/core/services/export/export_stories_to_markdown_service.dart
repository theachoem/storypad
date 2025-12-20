import 'dart:io';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';

/// Service to export stories to Obsidian-compatible markdown files
/// organized by year with proper YAML frontmatter.
class ExportStoriesToMarkdownService {
  /// Exports stories to markdown files organized by year.
  ///
  /// Creates a directory structure:
  /// ```
  /// outputDir/
  ///   2024/
  ///     2024.12.20 14.30.45 Story Title.md
  ///     2024.12.25 09.15.30 Another Story.md
  ///   2025/
  ///     2025.01.01 00.00.00 New Year Story.md
  /// ```
  ///
  /// Each markdown file contains:
  /// - YAML frontmatter with metadata
  /// - Story content with page headers
  /// - Page separators using `---`
  ///
  /// [tagNameGetter] - Optional callback to resolve tag ID to tag name
  /// [eventTypeGetter] - Optional callback to resolve event ID to event type
  static Future<Directory> call({
    required List<StoryDbModel> stories,
    required Directory outputDir,
    Future<String?> Function(int tagId)? tagNameGetter,
    Future<String?> Function(int eventId)? eventTypeGetter,
  }) async {
    // Group stories by year
    final Map<int, List<StoryDbModel>> storiesByYear = {};
    for (final story in stories) {
      final year = story.year;
      storiesByYear.putIfAbsent(year, () => []).add(story);
    }

    // Create year folders and export stories
    for (final entry in storiesByYear.entries) {
      final year = entry.key;
      final yearStories = entry.value;

      final yearDir = Directory('${outputDir.path}/$year');
      await yearDir.create(recursive: true);

      for (final story in yearStories) {
        await _exportStory(
          story,
          yearDir,
          tagNameGetter: tagNameGetter,
          eventTypeGetter: eventTypeGetter,
        );
      }
    }

    return outputDir;
  }

  static Future<void> _exportStory(
    StoryDbModel story,
    Directory yearDir, {
    Future<String?> Function(int tagId)? tagNameGetter,
    Future<String?> Function(int eventId)? eventTypeGetter,
  }) async {
    final content = story.latestContent ?? story.draftContent;
    if (content == null) return;

    // Build filename: YYYY.MM.DD HH.MM.SS Title.md
    final date = story.displayPathDate;
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}.'
        '${date.minute.toString().padLeft(2, '0')}.'
        '${date.second.toString().padLeft(2, '0')}';

    final title = content.title?.trim().isNotEmpty == true ? _sanitizeFilename(content.title!) : 'Untitled';
    final filename = '$dateStr $title.md';

    // Build YAML frontmatter
    final frontmatter = await _buildFrontmatter(
      story,
      tagNameGetter: tagNameGetter,
      eventTypeGetter: eventTypeGetter,
    );

    // Build markdown content with page headers
    final markdownContent = _buildMarkdownContent(content).trim();

    // Combine frontmatter + content
    // Format: ---\n[frontmatter]---\n[content] (no blank line after closing ---)
    final fullContent = '---\n${frontmatter.trimRight()}\n---\n$markdownContent';

    // Write file
    final file = File('${yearDir.path}/$filename');
    await file.writeAsString(fullContent);
  }

  static Future<String> _buildFrontmatter(
    StoryDbModel story, {
    Future<String?> Function(int tagId)? tagNameGetter,
    Future<String?> Function(int eventId)? eventTypeGetter,
  }) async {
    final buffer = StringBuffer();

    // Core metadata
    buffer.writeln('storypad_id: ${story.id}');

    // Optional fields
    if (story.starred == true) {
      buffer.writeln('starred: true');
    }

    if (story.feeling != null) {
      buffer.writeln('feeling: "${_escapeYaml(story.feeling!)}"');
    }

    // Tags (convert IDs to tag names)
    if (story.validTags?.isNotEmpty == true && tagNameGetter != null) {
      final tagNames = await Future.wait(
        story.validTags!.map((tagId) => tagNameGetter(tagId)),
      );

      final validTagNames = tagNames
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .map((name) => _sanitizeTag(name))
          .toList();

      if (validTagNames.isNotEmpty) {
        buffer.writeln('tags:');
        for (final tagName in validTagNames) {
          buffer.writeln('  - "$tagName"');
        }
      }
    }

    // Template ID (string for gallery template, int for custom template)
    if (story.galleryTemplateId != null) {
      buffer.writeln('storypad_template_id: ${story.galleryTemplateId}');
    } else if (story.templateId != null) {
      buffer.writeln('storypad_template_id: ${story.templateId}');
    }

    // Event type
    if (story.eventId != null && eventTypeGetter != null) {
      final eventType = await eventTypeGetter(story.eventId!);
      if (eventType != null && eventType.isNotEmpty) {
        buffer.writeln('event_type: $eventType');
      }
    }

    // Timestamps
    buffer.writeln('created_at: ${story.createdAt.toIso8601String()}');
    buffer.writeln('updated_at: ${story.updatedAt.toIso8601String()}');

    return buffer.toString();
  }

  static String _buildMarkdownContent(StoryContentDbModel content) {
    final buffer = StringBuffer();

    if (content.richPages != null && content.richPages!.isNotEmpty) {
      for (int i = 0; i < content.richPages!.length; i++) {
        final page = content.richPages![i];

        // Add page title as header
        if (page.title?.isNotEmpty == true) {
          buffer.write('# ${page.title}\n');
        } else if (content.richPages!.length > 1) {
          buffer.write('# Page ${i + 1}\n');
        }

        // Add page content
        if (page.body != null) {
          final pageMarkdown = QuillDeltaToPlainTextService.call(
            page.body!,
            markdown: true,
            includeMarkdownEmbeds: true,
            embedRelativePath: '../',
          ).trim(); // Trim to remove leading/trailing whitespace

          if (pageMarkdown.isNotEmpty) {
            buffer.write(pageMarkdown);
            if (!pageMarkdown.endsWith('\n')) {
              buffer.write('\n');
            }
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

    return buffer.toString();
  }

  static String _sanitizeFilename(String title) {
    // Remove or replace invalid filename characters
    // Keep it readable for Obsidian
    final sanitized = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '') // Remove invalid chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    // Limit length after sanitization
    return sanitized.length > 100 ? sanitized.substring(0, 100) : sanitized;
  }

  static String _sanitizeTag(String tag) {
    // Remove emojis, lowercase, and replace spaces with underscores for Obsidian compatibility
    return tag
        .toLowerCase() // Convert to lowercase for consistency
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '') // Remove special chars (including emojis) except underscore and hyphen
        .trim()
        .replaceAll(RegExp(r'^_+|_+$'), ''); // Remove leading/trailing underscores
  }

  static String _escapeYaml(String value) {
    return value.replaceAll('"', '\\"').replaceAll('\n', '\\n');
  }
}
