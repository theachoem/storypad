// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/adapters/objectbox/stories_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/services/story_db_constructor_service.dart';
import 'package:storypad/core/services/story_helper.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/stories/edit/edit_story_view_model.dart';
import 'package:storypad/views/stories/show/show_story_view_model.dart';

part 'story_db_model.g.dart';

List<String>? tagsFromJson(dynamic tags) {
  if (tags == null) return null;
  if (tags is List) return tags.map((e) => e.toString()).toList();
  return null;
}

@CopyWith()
@JsonSerializable()
class StoryDbModel extends BaseDbModel {
  static final StoriesBox db = StoriesBox();

  @override
  final int id;

  final int version;
  final PathType type;

  final int year;
  final int month;
  final int day;
  final int? hour;
  final int? minute;
  final int? second;

  final bool? starred;
  final String? feeling;

  @JsonKey(name: 'show_day_count')
  final bool? _showDayCount;

  @JsonKey(fromJson: tagsFromJson)
  final List<String>? tags;
  final List<int>? assets;

  /// load this manually when needed with [loadAllChanges]
  @JsonKey(name: 'changes')
  final List<StoryContentDbModel>? allChanges;

  @JsonKey(includeFromJson: false, includeToJson: false)
  late StoryContentDbModel? latestChange;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<String>? rawChanges;

  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  final DateTime? movedToBinAt;
  final String? lastSavedDeviceId;

  DateTime get displayPathDate {
    return DateTime(
      year,
      month,
      day,
      hour ?? createdAt.hour,
      minute ?? createdAt.minute,
    );
  }

  // tags are mistaken stores in DB in string.
  // we use integer here, buts its actuals value is still in <string>.
  List<int>? get validTags => tags?.map((e) => int.tryParse(e)).whereType<int>().toList();

  StoryDbModel({
    this.version = 1,
    required this.type,
    required this.id,
    required this.starred,
    required this.feeling,
    required bool? showDayCount,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.updatedAt,
    required this.createdAt,
    required this.tags,
    required this.assets,
    required this.movedToBinAt,
    required this.allChanges,
    required this.lastSavedDeviceId,
    this.rawChanges,
    this.latestChange,
  }) : _showDayCount = showDayCount {
    // By default, `allChanges` is null when fetched from the database for speed.
    // For backups, only `allChanges` is included, while `latestChange` and `rawChanges` are excluded.
    // This means that when converting a cloud backup JSON to a model,
    // `latestChange` and `rawChanges` should derive their values from `allChanges` instead.
    latestChange ??= allChanges?.last;
  }

  Duration get dateDifferentCount => DateTime.now().difference(displayPathDate);
  bool get showDayCount => _showDayCount ?? false;

  bool get viewOnly => unarchivable || inBins;

  bool get inBins => type == PathType.bins;
  bool get inArchives => type == PathType.archives;

  bool get editable => type == PathType.docs && !cloudViewing;
  bool get putBackAble => (inBins || unarchivable) && !cloudViewing;

  bool get archivable => type == PathType.docs && !cloudViewing;
  bool get unarchivable => type == PathType.archives && !cloudViewing;
  bool get canMoveToBin => !inBins && !cloudViewing;
  bool get hardDeletable => inBins && !cloudViewing;

  int? get willBeRemovedInDays {
    if (movedToBinAt != null) {
      DateTime willBeRemovedAt = movedToBinAt!.add(const Duration(days: 30));
      return willBeRemovedAt.difference(DateTime.now()).inDays;
    }
    return null;
  }

  bool sameDayAs(StoryDbModel story) {
    return [displayPathDate.year, displayPathDate.month, displayPathDate.day].join("-") ==
        [story.displayPathDate.year, story.displayPathDate.month, story.displayPathDate.day].join("-");
  }

  Future<StoryDbModel?> putBack({
    bool runCallbacks = true,
  }) async {
    if (!putBackAble) return null;

    return db.set(
      runCallbacks: runCallbacks,
      copyWith(
        type: PathType.docs,
        updatedAt: DateTime.now(),
        movedToBinAt: null,
      ),
    );
  }

  Future<StoryDbModel?> moveToBin({
    bool runCallbacks = true,
  }) async {
    if (!canMoveToBin) return null;

    return db.set(
      runCallbacks: runCallbacks,
      copyWith(
        type: PathType.bins,
        updatedAt: DateTime.now(),
        movedToBinAt: DateTime.now(),
      ),
    );
  }

  Future<StoryDbModel?> toggleStarred() async {
    if (!editable) return null;

    return db.set(copyWith(
      starred: !(starred == true),
      updatedAt: DateTime.now(),
    ));
  }

  Future<StoryDbModel?> archive() async {
    if (!archivable) return null;

    return db.set(copyWith(
      type: PathType.archives,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> delete() async {
    if (!hardDeletable) return;
    await db.delete(id);
  }

  Future<StoryDbModel?> changePathDate(DateTime date) async {
    if (!editable) return null;

    return db.set(copyWith(
      year: date.year,
      month: date.month,
      day: date.day,
      hour: displayPathDate.hour,
      minute: displayPathDate.minute,
    ));
  }

  factory StoryDbModel.fromNow() {
    final now = DateTime.now();
    return StoryDbModel.fromDate(now);
  }

  // use date for only path
  factory StoryDbModel.fromDate(
    DateTime date, {
    int? initialYear,
  }) {
    final now = DateTime.now();
    return StoryDbModel(
      year: initialYear ?? date.year,
      month: date.month,
      day: date.day,
      hour: date.hour,
      minute: date.minute,
      second: date.second,
      type: PathType.docs,
      id: now.millisecondsSinceEpoch,
      starred: false,
      feeling: null,
      showDayCount: false,
      latestChange: StoryContentDbModel.create(),
      allChanges: null,
      updatedAt: now,
      createdAt: now,
      tags: [],
      assets: [],
      movedToBinAt: null,
      rawChanges: null,
      lastSavedDeviceId: null,
    );
  }

  static Future<StoryDbModel> fromShowPage(ShowStoryViewModel viewModel) async {
    StoryContentDbModel content = await StoryHelper.buildContent(
      viewModel.draftContent!,
      viewModel.quillControllers,
    );

    return viewModel.story!.copyWith(
      updatedAt: DateTime.now(),
      latestChange: content,
    );
  }

  static Future<StoryDbModel> fromDetailPage(EditStoryViewModel viewModel) async {
    StoryContentDbModel content = await StoryHelper.buildContent(
      viewModel.draftContent!,
      viewModel.quillControllers,
    );

    Set<int> assets = {};
    for (var page in content.pages ?? []) {
      for (var node in page) {
        if (node is Map &&
            node['insert'] is Map &&
            node['insert']['image'] is String &&
            node['insert']['image'].toString().startsWith("storypad://")) {
          String image = node['insert']['image'];
          int? assetId = int.tryParse(image.split("storypad://assets/").lastOrNull ?? '');
          if (assetId != null) assets.add(assetId);
        }
      }
    }

    debugPrint("Found assets: $assets in ${viewModel.story?.id}");
    return viewModel.story!.copyWith(
      assets: assets.toList(),
      updatedAt: DateTime.now(),
      latestChange: content,
    );
  }

  factory StoryDbModel.startYearStory(int year) {
    StoryDbModel initialStory = StoryDbModel.fromDate(DateTime(year, 1, 1));
    String body =
        "This is your personal space for $year. Add your stories, thoughts, dreams, or memories and make it uniquely yours.\n";
    Delta delta = Delta()..insert(body);

    initialStory = initialStory.copyWith(
      latestChange: initialStory.latestChange!.copyWith(
        title: "Let's Begin: $year ✨",
        pages: [delta.toJson()],
        plainText: body,
      ),
    );

    return initialStory;
  }

  Future<StoryDbModel> loadAllChanges() async {
    return StoryDbConstructorService.loadAllChanges(this);
  }

  factory StoryDbModel.fromJson(Map<String, dynamic> json) => _$StoryDbModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StoryDbModelToJson(this);

  bool _cloudViewing = false;
  bool get cloudViewing => _cloudViewing;

  StoryDbModel markAsCloudViewing() {
    _cloudViewing = true;
    return this;
  }
}
