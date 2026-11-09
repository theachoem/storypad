import 'dart:io';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/quill/quill_delta_to_plain_text_service.dart';
import 'package:storypad/core/types/asset_type.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_audio_embed.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_media_embed.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_date_embed.dart';
import 'package:storypad/widgets/rich_editor/sp_embeds.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

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
  /// - Each page's stored Markdown, embeds as their stored HTML tags
  /// - Page separators using `---`
  ///
  /// [tagNameGetter] - Optional callback to resolve tag ID to tag name
  static Future<Directory> call({
    required List<StoryDbModel> stories,
    required Directory outputDir,
    Future<String?> Function(int tagId)? tagNameGetter,
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
        );
      }
    }

    return outputDir;
  }

  static Future<void> _exportStory(
    StoryDbModel story,
    Directory yearDir, {
    Future<String?> Function(int tagId)? tagNameGetter,
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

    // Event type (period marker, matched by date)
    if (story.event != null) {
      buffer.writeln('event_type: ${story.event!.eventType}');
    }

    // Timestamps
    buffer.writeln('created_at: ${story.createdAt.toIso8601String()}');
    buffer.writeln('updated_at: ${story.updatedAt.toIso8601String()}');

    return buffer.toString();
  }

  /// Each page's stored Markdown (title included, as its leading heading), pages separated by `---`.
  static String _buildMarkdownContent(StoryContentDbModel content) {
    final pages = content.richPages ?? const <StoryPageDbModel>[];
    return pages.map(_pageMarkdown).where((markdown) => markdown.isNotEmpty).join('\n\n---\n\n');
  }

  /// Writes Markdown like `SpEmbeds.codec`, except that asset paths are relative to the year folder each file is
  /// written to (see [_ExportMediaEmbed]).
  static final _exportCodec = StoryCodec(
    embeds: const [
      _ExportMediaEmbed(),
      _ExportAudioEmbed(),
      SpDateEmbed(),
    ],
  );

  /// [page]'s Markdown as stored: embeds stay the HTML tags they're stored as (`<img>`, `<video>`, `<audio>`,
  /// `<sp-album>`, `<time>`), only their asset paths change. A page still stored as Quill is converted the way opening
  /// it would -- unless that conversion would drop something, then it's written from its Quill (see
  /// [_legacyPageMarkdown]).
  static String _pageMarkdown(StoryPageDbModel page) {
    if (page.isLegacy && !page.checkConversion().isLossless) return _legacyPageMarkdown(page);
    return _exportCodec.encode(_withoutSpacing(SpEmbeds.codec.decodeNodes(page.markdown))).trim();
  }

  /// Stored Markdown keeps exactly what was typed so it reads back the same: an empty line as `&nbsp;`, trailing or
  /// whitespace-only spaces as `&#32;`. Other apps (Obsidian included) show those as literal text, so the export trims
  /// trailing whitespace and leaves out empty paragraphs -- the blank line between blocks already separates them. Code
  /// blocks are written as they are.
  static Iterable<DocumentNode> _withoutSpacing(List<DocumentNode> nodes) sync* {
    for (final node in nodes) {
      if (node is! TextNode || node.getMetadataValue(NodeMetadata.blockType) == codeAttribution) {
        yield node;
        continue;
      }

      final end = node.text.toPlainText().trimRight().length;
      if (end == 0 && node is ParagraphNode) continue;
      yield end == node.text.length ? node : node.copyTextNodeWith(text: node.text.copyText(0, end));
    }
  }

  // TODO(markdown): remove once every page is stored as Markdown (bulk conversion of legacy Quill pages, see
  // docs/app/features/story-editor.md) -- then drop the Quill-to-Markdown options of QuillDeltaToPlainTextService
  // (`includeMarkdownEmbeds`, `embedRelativePath`) if the text/CSV exports no longer need them either.
  /// A legacy page whose conversion isn't lossless (the app keeps it as Quill on disk too): the title as the same
  /// heading a converted page has, then the body flattened from Quill the way exports did before Markdown.
  static String _legacyPageMarkdown(StoryPageDbModel page) {
    final title = PageTitle.normalize(page.title);
    final body = QuillDeltaToPlainTextService.call(
      page.quillBody,
      markdown: true,
      includeMarkdownEmbeds: true,
      embedRelativePath: '../',
    ).trim();

    return [if (title != null) '${'#' * PageTitle.level} $title', if (body.isNotEmpty) body].join('\n\n');
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

/// `images/1.jpg` -> `../images/1.jpg`: assets sit next to the year folders. URLs are left as they are.
String _exportPath(String path) {
  final isAsset = AssetType.values.any((type) => path.startsWith('${type.subDirectory.relativePath}/'));
  return isAsset ? '../$path' : path;
}

/// Rewrites `src` once the HTML is built from the stored paths, which still tell a video (`videos/…`) from a photo.
StoryHtmlElement _withExportSources(StoryHtmlElement element) {
  return StoryHtmlElement(
    element.tag,
    attributes: {
      for (final MapEntry(:key, :value) in element.attributes.entries) key: key == 'src' ? _exportPath(value) : value,
    },
    children: element.children.map(_withExportSources).toList(),
    text: element.text,
  );
}

class _ExportMediaEmbed extends SpMediaEmbed {
  const _ExportMediaEmbed();

  @override
  StoryHtmlElement toHtml(SpMediaValue value) => _withExportSources(super.toHtml(value));
}

class _ExportAudioEmbed extends SpAudioEmbed {
  const _ExportAudioEmbed();

  @override
  StoryHtmlElement toHtml(String value) => _withExportSources(super.toHtml(value));
}
