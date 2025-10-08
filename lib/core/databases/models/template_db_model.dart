import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/adapters/objectbox/templates_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';

part 'template_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class TemplateDbModel extends BaseDbModel {
  static final TemplatesBox db = TemplatesBox();

  @override
  final int id;
  final int index;
  final List<int>? tags;

  @JsonKey(name: 'preferences')
  final StoryPreferencesDbModel? _preferences;
  StoryPreferencesDbModel get preferences => _preferences ?? StoryPreferencesDbModel.create();

  final StoryContentDbModel? content;
  final DateTime createdAt;

  @override
  final DateTime updatedAt;
  final String? lastSavedDeviceId;

  final DateTime? archivedAt;

  @override
  final DateTime? permanentlyDeletedAt;

  int? storiesCount;

  TemplateDbModel({
    required this.id,
    required this.tags,
    required this.content,
    StoryPreferencesDbModel? preferences,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
    required this.lastSavedDeviceId,
    required this.permanentlyDeletedAt,
    int? index,
  }) : index = index ?? 0,
       _preferences = preferences;

  bool get archived => archivedAt != null;

  @override
  Map<String, dynamic> toJson() => _$TemplateDbModelToJson(this);
  factory TemplateDbModel.fromJson(Map<String, dynamic> json) => _$TemplateDbModelFromJson(json);
}
