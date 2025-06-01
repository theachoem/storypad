import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/adapters/objectbox/templates_box.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/databases/models/story_content_db_model.dart';

part 'template_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class TemplateDbModel extends BaseDbModel {
  static final TemplatesBox db = TemplatesBox();

  @override
  final int id;
  final int index;
  final List<int>? tags;
  final StoryContentDbModel? content;
  final DateTime createdAt;

  @override
  final DateTime updatedAt;
  final String? lastSavedDeviceId;

  @override
  final DateTime? permanentlyDeletedAt;

  int? storiesCount;

  TemplateDbModel({
    required this.id,
    required this.tags,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSavedDeviceId,
    this.permanentlyDeletedAt,
    int? index,
  }) : index = index ?? 0;

  @override
  Map<String, dynamic> toJson() => _$TemplateDbModelToJson(this);
  factory TemplateDbModel.fromJson(Map<String, dynamic> json) => _$TemplateDbModelFromJson(json);
}
