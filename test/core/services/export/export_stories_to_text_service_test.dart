import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/export/export_stories_to_text_service.dart';
import 'package:storypad/core/types/path_type.dart';

void main() {
  group('ExportStoriesToTextService', () {
    late Directory tempDir;

    setUp(() async {
      // Create a temporary directory for each test
      tempDir = await Directory.systemTemp.createTemp('text_export_test_');
    });

    tearDown(() async {
      // Clean up after each test
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should export stories to a single text file', () async {
      // Arrange
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
      ];

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      final result = await ExportStoriesToTextService.call(
        stories: stories,
        outputFile: outputFile,
      );

      // Assert
      expect(await result.exists(), true);

      final content = await result.readAsString();
      expect(content, contains("StoryPad ID: 1735537709471"));
      expect(content, contains("Title: Let's Begin: 2025 ✨"));
      expect(content, contains('Date: 2025-01-04'));
      expect(content, contains('Hi there, this is me from 2025!'));
      expect(content, contains('###'));
      expect(content, contains('StoryPad ID: 1715024221522'));
      expect(content, contains('Title: Another Story'));
      expect(content, contains('Date: 2024-05-07'));
      expect(content, contains('Another tough week again.'));
    });

    test('should include metadata when provided', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Story with Metadata",
        content: "Test content",
        starred: true,
        feeling: "excited",
        tags: [20, 21],
        eventId: 42,
      );

      // Mock tag getter
      Future<String?> tagNameGetter(int tagId) async {
        return {
          20: 'Personal',
          21: 'Workout 🏋️',
        }[tagId];
      }

      // Mock event getter
      Future<String?> eventTypeGetter(int eventId) async {
        return eventId == 42 ? 'period' : null;
      }

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
        tagNameGetter: tagNameGetter,
        eventTypeGetter: eventTypeGetter,
      );

      // Assert
      final content = await outputFile.readAsString();
      expect(content, contains('StoryPad ID: 1'));
      expect(content, contains('Title: Story with Metadata'));
      expect(content, contains('Tags: Personal, Workout 🏋️'));
      expect(content, contains('Event: period'));
      expect(content, contains('Feeling: excited'));
      expect(content, contains('Test content'));
    });

    test('should handle stories without optional metadata', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Simple Story",
        content: "Just some text.",
      );

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
      );

      // Assert
      final content = await outputFile.readAsString();
      expect(content, contains('StoryPad ID: 1'));
      expect(content, contains('Title: Simple Story'));
      expect(content, contains('Date: 2025-01-01'));
      expect(content, contains('Just some text.'));
      expect(content, isNot(contains('Tags:')));
      expect(content, isNot(contains('Event:')));
      expect(content, isNot(contains('Feeling:')));
    });

    test('should skip title when title is null or empty', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: null,
        content: "Content without title",
      );

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
      );

      // Assert
      final content = await outputFile.readAsString();
      expect(content, contains('StoryPad ID: 1'));
      expect(content, isNot(contains('Title:')));
      expect(content, contains('Content without title'));
      // Should have StoryPad ID as first line
      expect(content.trim().startsWith('StoryPad ID: 1'), true);
    });

    test('should convert formatted content to plain text', () async {
      // Arrange: Story with formatted content
      final story = _createStoryWithRichPages(
        id: 1,
        year: 2025,
        month: 1,
        day: 4,
        pages: [
          StoryPageDbModel(
            id: 1,
            title: "Formatted Story",
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

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
      );

      // Assert: Formatting should be stripped
      final content = await outputFile.readAsString();
      expect(content, contains('Hi there, bold text and italic text!'));
      expect(content, isNot(contains('**')));
      expect(content, isNot(contains('*')));
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

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
      );

      // Assert
      final content = await outputFile.readAsString();
      expect(content, contains('Page 1'));
      expect(content, contains('First page content'));
      expect(content, contains('---'));
      expect(content, contains('Page 2'));
      expect(content, contains('Second page content'));
      expect(content, contains('Page 3'));
      expect(content, contains('Third page content'));

      // Should have 2 page separators (between 3 pages)
      expect('---'.allMatches(content).length, 2);
    });

    test('should not include separators for last story', () async {
      // Arrange
      final stories = [
        _createStory(
          id: 1,
          year: 2025,
          month: 1,
          day: 1,
          title: "Story 1",
          content: "First story",
        ),
        _createStory(
          id: 2,
          year: 2025,
          month: 1,
          day: 2,
          title: "Story 2",
          content: "Last story",
        ),
      ];

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: stories,
        outputFile: outputFile,
      );

      // Assert
      final content = await outputFile.readAsString();

      // Should have only 1 story separator (between 2 stories)
      expect('###'.allMatches(content).length, 1);

      // Should not end with a separator
      expect(content.trim().endsWith('###'), false);
    });

    test('should handle empty story list', () async {
      // Arrange
      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [],
        outputFile: outputFile,
      );

      // Assert: File should be created but empty
      expect(await outputFile.exists(), true);
      final content = await outputFile.readAsString();
      expect(content.trim(), isEmpty);
    });

    test('should skip stories without content', () async {
      // Arrange: Story with no content
      final validStory = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Valid Story",
        content: "Content here",
      );

      final invalidStory = StoryDbModel(
        id: 2,
        type: PathType.docs,
        year: 2025,
        month: 1,
        day: 2,
        hour: 0,
        minute: 0,
        second: 0,
        starred: false,
        feeling: null,
        tags: null,
        assets: null,
        latestContent: null,
        draftContent: null,
        createdAt: DateTime(2025, 1, 2),
        updatedAt: DateTime(2025, 1, 2),
        movedToBinAt: null,
        galleryTemplateId: null,
        templateId: null,
        eventId: null,
        lastSavedDeviceId: null,
        permanentlyDeletedAt: null,
      );

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [validStory, invalidStory],
        outputFile: outputFile,
      );

      // Assert: Only valid story should be in output
      final content = await outputFile.readAsString();
      expect(content, contains('StoryPad ID: 1'));
      expect(content, contains('Title: Valid Story'));
      expect(content, contains('Content here'));

      // Should have no story separators (only 1 valid story)
      expect('###'.allMatches(content).length, 0);
    });

    test('should format date correctly with padding', () async {
      // Arrange
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 4,
        hour: 9,
        minute: 5,
        second: 3,
        title: "Test",
        content: "Test",
      );

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
      );

      // Assert: Date should be padded
      final content = await outputFile.readAsString();
      // Note: seconds are always 00 because displayPathDate only includes hour and minute
      expect(content, contains('Date: 2025-01-04 09:05:00'));
    });

    test('should include images as markdown embeds', () async {
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

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
      );

      // Assert: Images should appear as markdown embeds
      final content = await outputFile.readAsString();
      expect(content, contains('StoryPad ID: 1'));
      expect(content, contains('Title: Story with Image'));
      expect(content, contains('Check out this image:'));
      expect(content, contains('![image](images/1759081859921.jpg)'));
    });

    test('should handle single page story without page title', () async {
      // Arrange: Single page story
      final story = _createStory(
        id: 1,
        year: 2025,
        month: 1,
        day: 1,
        title: "Single Page",
        content: "Simple content",
      );

      final outputFile = File('${tempDir.path}/export.txt');

      // Act
      await ExportStoriesToTextService.call(
        stories: [story],
        outputFile: outputFile,
      );

      // Assert: Should not add "Page 1" title for single-page stories
      final content = await outputFile.readAsString();
      expect(content, contains('Single Page'));
      expect(content, contains('Simple content'));
      expect(content, isNot(contains('Page 1')));
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
