import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/types/page_layout_type.dart';

part 'story_editing_preferences_object.g.dart';

@CopyWith()
@JsonSerializable()
class StoryEditingPreferencesObject {
  final bool enableTitle;
  final int? defaultColorSeedValue;
  final int? defaultColorTone;
  final String? defaultBackgroundImagePath;
  final PageLayoutType defaultLayoutType;

  StoryEditingPreferencesObject({
    this.defaultColorSeedValue,
    this.defaultColorTone,
    this.defaultBackgroundImagePath,
    bool? enableTitle,
    PageLayoutType? defaultLayoutType,
  }) : enableTitle = enableTitle ?? true,
       defaultLayoutType = defaultLayoutType ?? PageLayoutType.list;

  Map<String, dynamic> toJson() => _$StoryEditingPreferencesObjectToJson(this);
  factory StoryEditingPreferencesObject.fromJson(Map<String, dynamic> json) =>
      _$StoryEditingPreferencesObjectFromJson(json);
}
