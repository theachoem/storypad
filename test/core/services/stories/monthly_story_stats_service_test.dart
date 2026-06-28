import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/services/stories/monthly_story_stats_service.dart';
import 'package:storypad/core/types/path_type.dart';

void main() {
  group('MonthlyStoryStatsService.getByMonth', () {
    test('returns an empty map when there are no stories', () {
      expect(MonthlyStoryStatsService.getByMonth(stories: []), isEmpty);
    });

    test('groups stories by month and counts stories per month', () {
      final stats = MonthlyStoryStatsService.getByMonth(
        stories: [
          _story(id: 1, year: 2024, month: 1, day: 3),
          _story(id: 2, year: 2024, month: 1, day: 10),
          _story(id: 3, year: 2024, month: 5, day: 7),
        ],
        now: DateTime(2024, 12, 31),
      );

      expect(stats.keys.toSet(), {1, 5});
      expect(stats[1]!.storyCount, 2);
      expect(stats[5]!.storyCount, 1);
    });

    test('counts distinct active days, ignoring multiple stories on the same day', () {
      final stats = MonthlyStoryStatsService.getByMonth(
        stories: [
          _story(id: 1, year: 2024, month: 3, day: 4),
          _story(id: 2, year: 2024, month: 3, day: 4),
          _story(id: 3, year: 2024, month: 3, day: 9),
        ],
        now: DateTime(2024, 12, 31),
      );

      expect(stats[3]!.activeDays, 2);
    });

    test('sums embedded photos and voices across the month', () {
      final stats = MonthlyStoryStatsService.getByMonth(
        stories: [
          _story(id: 1, year: 2024, month: 2, day: 1, images: 2, audios: 1),
          _story(id: 2, year: 2024, month: 2, day: 2, images: 3, audios: 0),
        ],
        now: DateTime(2024, 12, 31),
      );

      expect(stats[2]!.photoCount, 5);
      expect(stats[2]!.voiceCount, 1);
    });

    test('totalDays is the full calendar length for a past month', () {
      final stats = MonthlyStoryStatsService.getByMonth(
        stories: [_story(id: 1, year: 2024, month: 2, day: 1)],
        now: DateTime(2024, 12, 31),
      );

      // 2024 is a leap year.
      expect(stats[2]!.totalDays, 29);
    });

    test('totalDays is days elapsed so far for the in-progress month', () {
      final stats = MonthlyStoryStatsService.getByMonth(
        stories: [_story(id: 1, year: 2024, month: 6, day: 5)],
        now: DateTime(2024, 6, 15),
      );

      expect(stats[6]!.totalDays, 15);
    });
  });
}

StoryDbModel _story({
  required int id,
  required int year,
  required int month,
  required int day,
  int images = 0,
  int audios = 0,
}) {
  final DateTime now = DateTime(year, month, day);

  final List<Map<String, dynamic>> body = [
    {"insert": "Entry\n"},
    for (int i = 0; i < images; i++)
      {
        "insert": {"image": "images/$id-$i.jpg"},
      },
    for (int i = 0; i < audios; i++)
      {
        "insert": {"audio": "audio/$id-$i.m4a"},
      },
  ];

  return StoryDbModel(
    id: id,
    type: PathType.docs,
    year: year,
    month: month,
    day: day,
    hour: 0,
    minute: 0,
    second: 0,
    starred: false,
    pinned: false,
    feeling: null,
    tags: null,
    assets: null,
    latestContent: StoryContentDbModel(
      id: id + 1,
      title: null,
      plainText: "Entry",
      createdAt: now,
      richPages: [
        StoryPageDbModel(id: id + 2, title: null, body: body),
      ],
    ),
    draftContent: null,
    createdAt: now,
    updatedAt: now,
    movedToBinAt: null,
    galleryTemplateId: null,
    templateId: null,
    event: null,
    lastSavedDeviceId: "test-device",
    permanentlyDeletedAt: null,
  );
}
