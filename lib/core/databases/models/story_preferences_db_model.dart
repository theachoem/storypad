import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';

part 'story_preferences_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class StoryPreferencesDbModel extends BaseDbModel {
  final String? starIcon;
  final bool? showDayCount;

  StoryPreferencesDbModel({
    required this.showDayCount,
    required this.starIcon,
  });

  @override
  int get id => 0;

  @override
  DateTime? get updatedAt => null;

  factory StoryPreferencesDbModel.create() {
    return StoryPreferencesDbModel(
      showDayCount: false,
      starIcon: null,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$StoryPreferencesDbModelToJson(this);
  factory StoryPreferencesDbModel.fromJson(Map<String, dynamic> json) => _$StoryPreferencesDbModelFromJson(json);
}
