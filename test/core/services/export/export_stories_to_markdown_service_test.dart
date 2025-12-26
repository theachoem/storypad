import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/export/export_stories_to_markdown_service.dart';
import 'package:storypad/core/types/path_type.dart';

void main() {
  group('ExportStoriesToMarkdownService', () {
    late Directory tempDir;

    setUp(() async {
      // Create a temporary directory for each test
      tempDir = await Directory.systemTemp.createTemp('markdown_export_test_');
    });

    tearDown(() async {
      // Clean up after each test
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should export stories organized by year', () async {
      // Arrange: Create stories from different years
      final stories = [
        _createStory(
          id: 1735537709471,
          year: 2025,
          month: 1,
          day: 4,
          title: "Let's Begin: 2025 ✨",
          content: "Hi there, this is me from 2025!",
        ),
        _createStory(
          id: 1715024221522,
          year: 2024,
          month: 5,
          day: 7,
          title: "Another Story",
          content: "Another tough week again.",
        ),
        _createStory(
          id: 1710076461049,
          year: 2024,
          month: 3,
          day: 10,
          title: "Brown app idea",
          content: "We can put it in ABA.",
        ),
      ];

      // Act: Export stories
      final result = await ExportStoriesToMarkdownService.call(
        stories: stories,
        outputDir: tempDir,
      );

      // Assert: Check directory structure
      expect(await result.exists(), true);

      final year2024Dir = Directory('${tempDir.path}/2024');
      final year2025Dir = Directory('${tempDir.path}/2025');

      expect(await year2024Dir.exists(), true);
      expect(await year2025Dir.exists(), true);

      // Check file count
      final year2024Files = year2024Dir.listSync().whereType<File>().toList();
      final year2025Files = year2025Dir.listSync().whereType<File>().toList();

      expect(year2024Files.length, 2);
      expect(year2025Files.length, 1);
    });

    test('should have correct spacing between frontmatter and content', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Test Story",
        content: "Test content",
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final files = Directory('${tempDir.path}/2025').listSync().whereType<File>().toList();
      expect(files.length, 1);

      final content = await files.first.readAsString();

      // Should have NO blank line between --- and content
      expect(content.contains('---\n# Test Story\n'), true, reason: 'Should have no blank line after closing ---');
      expect(content.contains('---\n\n# Test Story'), false, reason: 'Should NOT have blank line after closing ---');

      // Should not have multiple consecutive blank lines
      expect(content.contains('\n\n\n'), false, reason: 'Should not have multiple consecutive blank lines');

      // Frontmatter should not have trailing blank lines before ---
      final lines = content.split('\n');
      final closingDashIndex = lines.lastIndexOf('---');
      expect(closingDashIndex > 0, true);
      expect(lines[closingDashIndex - 1].trim().isNotEmpty, true, reason: 'No blank line before closing ---');
    });

    test('should have correct spacing between page title and content', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Test Story",
        content: "First line of content",
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final files = Directory('${tempDir.path}/2025').listSync().whereType<File>().toList();
      final content = await files.first.readAsString();

      // Should have title followed by content without extra blank lines
      expect(
        content.contains('# Test Story\nFirst line'),
        true,
        reason: 'Title and content should be on consecutive lines',
      );
      expect(content.contains('# Test Story\n\nFirst line'), false, reason: 'Should not have blank line after title');
    });

    test('should generate correct filename format', () async {
      // Arrange
      final story = _createStory(
        id: 1735537709471,
        year: 2025,
        month: 1,
        day: 4,
        hour: 14,
        minute: 30,
        second: 45,
        title: "My Story Title",
        content: "Content here",
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert: Check filename format (YYYY.MM.DD HH.MM.SS Title.md)
      // Note: seconds are always 00 because displayPathDate only includes hour and minute
      final year2025Dir = Directory('${tempDir.path}/2025');
      final files = year2025Dir.listSync().whereType<File>().toList();

      expect(files.length, 1);
      expect(files.first.path, contains('2025.01.04 14.30.00 My Story Title.md'));
    });

    test('should sanitize invalid characters in filename', () async {
      // Arrange: Story with problematic title
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: 'Invalid: <Title> with "Quotes" and /Slashes\\',
        content: "Content",
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert: Filename should be sanitized
      final yearDir = Directory('${tempDir.path}/2025');
      final files = yearDir.listSync().whereType<File>().toList();

      expect(files.length, 1);
      expect(files.first.path, contains('Invalid Title with Quotes and Slashes'));
      expect(files.first.path, isNot(contains(':')));
      expect(files.first.path, isNot(contains('<')));
      expect(files.first.path, isNot(contains('"')));
    });

    test('should use "Untitled" for stories without title', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: null,
        content: "Content without title",
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final files = yearDir.listSync().whereType<File>().toList();

      expect(files.length, 1);
      expect(files.first.path, contains('Untitled.md'));
    });

    test('should generate YAML frontmatter with basic metadata', () async {
      // Arrange
      final story = _createStory(
        id: 1735537709471,
        year: 2025,
        month: 1,
        day: 4,
        hour: 14,
        minute: 30,
        second: 45,
        title: "Test Story",
        content: "Content",
        starred: true,
        feeling: "excited",
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final file = yearDir.listSync().whereType<File>().first;
      final content = await file.readAsString();

      expect(content, contains('---'));
      expect(content, contains('storypad_id: 1735537709471'));
      expect(content, contains('starred: true'));
      expect(content, contains('feeling: "excited"'));
      expect(content, contains('created_at: 2025-01-04'));
      expect(content, contains('updated_at:'));
    });

    test('should include tags when tagNameGetter is provided', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Story with Tags",
        content: "Content",
        tags: [20, 21],
      );

      // Mock tag getter
      Future<String?> tagNameGetter(int tagId) async {
        return {
          20: 'Personal',
          21: 'Workout 🏋️',
        }[tagId];
      }

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
        tagNameGetter: tagNameGetter,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final file = yearDir.listSync().whereType<File>().first;
      final content = await file.readAsString();

      expect(content, contains('tags:'));
      // Tags are sanitized: lowercase, spaces become underscores, emojis removed
      expect(content, contains('- "personal"'));
      expect(content, contains('- "workout"'));
    });

    test('should include event type when eventTypeGetter is provided', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Story with Event",
        content: "Content",
        eventId: 42,
      );

      // Mock event getter
      Future<String?> eventTypeGetter(int eventId) async {
        return eventId == 42 ? 'period' : null;
      }

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
        eventTypeGetter: eventTypeGetter,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final file = yearDir.listSync().whereType<File>().first;
      final content = await file.readAsString();

      expect(content, contains('event_type: period'));
    });

    test('should include template IDs in frontmatter', () async {
      // Arrange: Story with gallery template
      final story1 = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Story with Gallery Template",
        content: "Content",
        galleryTemplateId: "template_123",
      );

      // Story with custom template
      final story2 = _createStory(
        id: 2,
        year: 2025,
        month: 1,
        day: 2,
        title: "Story with Custom Template",
        content: "Content",
        templateId: 42,
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story1, story2],
        outputDir: tempDir,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final files = yearDir.listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));

      final content1 = await files[0].readAsString();
      final content2 = await files[1].readAsString();

      expect(content1, contains('storypad_template_id: template_123'));
      expect(content2, contains('storypad_template_id: 42'));
    });

    test('should generate markdown content from Quill Delta', () async {
      // Arrange: Story with formatted content
      final story = _createStoryWithRichPages(
        id: 1735537709471,
        year: 2025,
        month: 1,
        day: 4,
        pages: [
          StoryPageDbModel(
            id: 1,
            title: "Let's Begin: 2025 ✨",
            body: [
              {"insert": "Hi there, "},
              {
                "insert": "bold text",
                "attributes": {"bold": true},
              },
              {"insert": " and "},
              {
                "insert": "italic text",
                "attributes": {"italic": true},
              },
              {"insert": "!\n"},
            ],
          ),
        ],
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final file = yearDir.listSync().whereType<File>().first;
      final content = await file.readAsString();

      expect(content, contains('# Let\'s Begin: 2025 ✨'));
      expect(content, contains('Hi there, **bold text** and *italic text*!'));
    });

    test('should separate multiple pages with horizontal rules', () async {
      // Arrange: Story with multiple pages
      final story = _createStoryWithRichPages(
        id: 1,
        year: 2025,
        month: 1,
        day: 4,
        pages: [
          StoryPageDbModel(
            id: 1,
            title: "Page 1",
            body: [
              {"insert": "First page content\n"},
            ],
          ),
          StoryPageDbModel(
            id: 2,
            title: "Page 2",
            body: [
              {"insert": "Second page content\n"},
            ],
          ),
          StoryPageDbModel(
            id: 3,
            title: null,
            body: [
              {"insert": "Third page content\n"},
            ],
          ),
        ],
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final file = yearDir.listSync().whereType<File>().first;
      final content = await file.readAsString();

      expect(content, contains('# Page 1'));
      expect(content, contains('First page content'));
      expect(content, contains('---'));
      expect(content, contains('# Page 2'));
      expect(content, contains('Second page content'));
      expect(content, contains('# Page 3'));
      expect(content, contains('Third page content'));
    });

    test('should include image embeds in markdown', () async {
      // Arrange: Story with image embed
      final story = _createStoryWithRichPages(
        id: 1,
        year: 2025,
        month: 1,
        day: 4,
        pages: [
          StoryPageDbModel(
            id: 1,
            title: "Story with Image",
            body: [
              {"insert": "Check out this image:\n"},
              {
                "insert": {"image": "images/1759081859921.jpg"},
              },
              {"insert": "\n"},
            ],
          ),
        ],
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final file = yearDir.listSync().whereType<File>().first;
      final content = await file.readAsString();

      expect(content, contains('Check out this image:'));
      expect(content, contains('![image](../images/1759081859921.jpg)'));
    });

    test('should escape special characters in YAML values', () async {
      // Arrange: Story with special characters in feeling
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Test",
        content: "Content",
        feeling: 'Happy "Excited" Day\nWith newlines',
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert
      final yearDir = Directory('${tempDir.path}/2025');
      final file = yearDir.listSync().whereType<File>().first;
      final content = await file.readAsString();

      expect(content, contains('feeling: "Happy \\"Excited\\" Day\\nWith newlines"'));
    });

    test('should handle empty story list', () async {
      // Act
      final result = await ExportStoriesToMarkdownService.call(
        stories: [],
        outputDir: tempDir,
      );

      // Assert: Directory exists but is empty
      expect(await result.exists(), true);
      final subdirs = result.listSync().toList();
      expect(subdirs.isEmpty, true);
    });

    test('should handle stories without content', () async {
      // Arrange: Story with no content
      final story = StoryDbModel(
        id: 1,
        type: PathType.docs,
        year: 2025,
        month: 1,
        day: 1,
        hour: 0,
        minute: 0,
        second: 0,
        starred: false,
        pinned: false,
        feeling: null,
        tags: null,
        assets: null,
        latestContent: null,
        draftContent: null,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        movedToBinAt: null,
        galleryTemplateId: null,
        templateId: null,
        eventId: null,
        lastSavedDeviceId: null,
        permanentlyDeletedAt: null,
      );

      // Act
      await ExportStoriesToMarkdownService.call(
        stories: [story],
        outputDir: tempDir,
      );

      // Assert: No files should be created for stories without content
      final yearDir = Directory('${tempDir.path}/2025');
      expect(await yearDir.exists(), true);
      final files = yearDir.listSync().whereType<File>().toList();
      expect(files.isEmpty, true);
    });
  });
}

// Helper function to create a story with simple text content
StoryDbModel _createStory({
  required int id,
  required int year,
  required int month,
  required int day,
  int hour = 0,
  int minute = 0,
  int second = 0,
  String? title,
  required String content,
  bool starred = false,
  bool pinned = false,
  String? feeling,
  List<int>? tags,
  int? eventId,
  String? galleryTemplateId,
  int? templateId,
}) {
  final now = DateTime(year, month, day, hour, minute, second);

  return StoryDbModel(
    id: id,
    type: PathType.docs,
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
    second: second,
    starred: starred,
    pinned: pinned,
    feeling: feeling,
    tags: tags?.map((e) => e.toString()).toList(),
    assets: null,
    latestContent: StoryContentDbModel(
      id: id + 1,
      title: title,
      plainText: content,
      createdAt: now,
      richPages: [
        StoryPageDbModel(
          id: id + 2,
          title: title,
          body: [
            {"insert": "$content\n"},
          ],
        ),
      ],
    ),
    draftContent: null,
    createdAt: now,
    updatedAt: now,
    movedToBinAt: null,
    galleryTemplateId: galleryTemplateId,
    templateId: templateId,
    eventId: eventId,
    lastSavedDeviceId: "test-device",
    permanentlyDeletedAt: null,
  );
}

// Helper function to create a story with custom rich pages
StoryDbModel _createStoryWithRichPages({
  required int id,
  required int year,
  required int month,
  required int day,
  int hour = 0,
  int minute = 0,
  int second = 0,
  required List<StoryPageDbModel> pages,
}) {
  final now = DateTime(year, month, day, hour, minute, second);

  return StoryDbModel(
    id: id,
    type: PathType.docs,
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
    second: second,
    starred: false,
    pinned: false,
    feeling: null,
    tags: null,
    assets: null,
    latestContent: StoryContentDbModel(
      id: id + 1,
      title: pages.first.title,
      plainText: "Generated content",
      createdAt: now,
      richPages: pages,
    ),
    draftContent: null,
    createdAt: now,
    updatedAt: now,
    movedToBinAt: null,
    galleryTemplateId: null,
    templateId: null,
    eventId: null,
    lastSavedDeviceId: "test-device",
    permanentlyDeletedAt: null,
  );
}
