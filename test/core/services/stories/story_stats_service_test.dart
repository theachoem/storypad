import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/story_page_db_model.dart';
import 'package:storypad/core/databases/models/tag_category_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/objects/stats/stats_range.dart';
import 'package:storypad/core/services/stories/story_stats_service.dart';
import 'package:storypad/core/types/path_type.dart';

void main() {
  // Tag dictionary shared across tests: two feelings, one activity, one person,
  // one plain tag.
  final List<TagDbModel> tags = [
    _emojiTag(1, '😄', TagCategoryDbModel.feeling().id),
    _emojiTag(2, '😢', TagCategoryDbModel.feeling().id),
    _emojiTag(3, '🏃', TagCategoryDbModel.activity().id),
    _person(4, 'Alice'),
    _topic(5, 'Work'),
  ];

  group('StoryStatsService.compute', () {
    test('returns an empty object when no stories fall in the range', () {
      final stats = StoryStatsService.compute(
        stories: [_story(id: 1, year: 2024, month: 1, day: 5)],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      expect(stats.isEmpty, isTrue);
      expect(stats.entryCount, 0);
    });

    test('filters stories outside the range and counts those inside', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 3),
          _story(id: 2, year: 2024, month: 6, day: 20),
          _story(id: 3, year: 2024, month: 7, day: 1), // out of range
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      expect(stats.entryCount, 2);
      expect(stats.activeDays, 2);
    });

    test('aggregates words, photos and voices from content', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 3, images: 2, audios: 1, words: 10),
          _story(id: 2, year: 2024, month: 6, day: 4, images: 1, audios: 0, words: 5),
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      expect(stats.photoCount, 3);
      expect(stats.voiceCount, 1);
      expect(stats.wordCount, 15);
    });

    test('counts videos separately from photos, and excludes them from photoCount', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 3, images: 2, videos: 1),
          // A video-only story -- must count toward videoCount, never photoCount.
          _story(id: 2, year: 2024, month: 6, day: 4, videos: 2),
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      expect(stats.photoCount, 2);
      expect(stats.videoCount, 3);
    });

    test('videoStoryIds only contains stories with a video, never a photo-only story', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 1, images: 1), // photo only
          _story(id: 2, year: 2024, month: 6, day: 2, videos: 1), // video only
          _story(id: 3, year: 2024, month: 6, day: 3, images: 1, videos: 1), // both
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      // Regression guard: tapping the "Photos" chip must never open a story
      // that has no photo in it (a video-only story previously leaked in via
      // the shared `images()` extractor).
      expect(stats.photoStoryIds, {1, 3});
      expect(stats.videoStoryIds, {2, 3});
    });

    test('ranks top feelings, activities, people and tags', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 1, tagIds: [1, 3, 4, 5]),
          _story(id: 2, year: 2024, month: 6, day: 2, tagIds: [1, 3]),
          _story(id: 3, year: 2024, month: 6, day: 3, tagIds: [2]),
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      expect(stats.topFeelings.first.emoji, '😄');
      expect(stats.topFeelings.first.count, 2);
      expect(stats.topActivities.single.emoji, '🏃');
      expect(stats.topActivities.single.count, 2);
      expect(stats.topPeople.single.label, 'Alice');
      expect(stats.topTags.single.label, 'Work');
    });

    test('counts places and countries from located stories', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 1, place: _place('Cafe', 'Cambodia')),
          _story(id: 2, year: 2024, month: 6, day: 2, place: _place('Cafe', 'Cambodia')),
          _story(id: 3, year: 2024, month: 6, day: 3, place: _place('Park', 'Thailand')),
          _story(id: 4, year: 2024, month: 6, day: 4),
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      expect(stats.locatedCount, 3);
      expect(stats.topPlaces.first.label, 'Cafe');
      expect(stats.topPlaces.first.count, 2);
      expect(stats.topCountries.map((e) => e.label).toSet(), {'Cambodia', 'Thailand'});
    });

    test('exposes the backing tag id on each ranked item for filtering', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 1, tagIds: [1, 3, 4, 5]),
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 12, 31),
      );

      expect(stats.topFeelings.single.tagId, 1);
      expect(stats.topActivities.single.tagId, 3);
      expect(stats.topPeople.single.tagId, 4);
      expect(stats.topTags.single.tagId, 5);
      // Places have no tag-based filter.
      expect(stats.topPlaces, isEmpty);
    });

    test('totalDays is days elapsed so far for the in-progress range', () {
      final stats = StoryStatsService.compute(
        stories: [
          _story(id: 1, year: 2024, month: 6, day: 13),
        ],
        allTags: tags,
        range: StatsRange.month(DateTime(2024, 6, 1)),
        now: DateTime(2024, 6, 15),
      );

      // June so far is 15 days elapsed, not the full 30.
      expect(stats.totalDays, 15);
    });
  });
}

TagDbModel _emojiTag(int id, String emoji, int categoryId) =>
    TagDbModel.emoji(emoji, categoryId: categoryId).copyWith(id: id);

TagDbModel _person(int id, String title) => TagDbModel(
  id: id,
  version: 0,
  title: title,
  emoji: null,
  categoryId: TagCategoryDbModel.peopleId,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  lastSavedDeviceId: null,
  permanentlyDeletedAt: null,
);

TagDbModel _topic(int id, String title) => TagDbModel(
  id: id,
  version: 0,
  title: title,
  emoji: null,
  categoryId: null,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  lastSavedDeviceId: null,
  permanentlyDeletedAt: null,
);

PlaceDbModel _place(String name, String country) =>
    PlaceDbModel(latitude: 0, longitude: 0, placeName: name, country: country);

StoryDbModel _story({
  required int id,
  required int year,
  required int month,
  required int day,
  int images = 0,
  int videos = 0,
  int audios = 0,
  int words = 0,
  List<int> tagIds = const [],
  PlaceDbModel? place,
}) {
  final DateTime now = DateTime(year, month, day);

  final List<Map<String, dynamic>> body = [
    {"insert": "Entry\n"},
    for (int i = 0; i < images; i++)
      {
        "insert": {"image": "images/$id-$i.jpg"},
      },
    // Video reuses the `image` embed key -- see docs/app/features/media.md.
    for (int i = 0; i < videos; i++)
      {
        "insert": {"image": "videos/$id-$i.mp4"},
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
    tags: tagIds.isEmpty ? null : tagIds.map((e) => e.toString()).toList(),
    assets: null,
    place: place,
    latestContent: StoryContentDbModel(
      id: id + 1,
      title: null,
      plainText: "Entry",
      createdAt: now,
      richPages: [
        StoryPageDbModel(id: id + 2, title: null, body: body, wordCount: words),
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
