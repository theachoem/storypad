import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/types/page_layout_type.dart';

part 'default_story_preferences_object.g.dart';

@CopyWith()
@JsonSerializable()
class DefaultStoryPreferencesObject {
  final int? defaultColorSeedValue;
  final int? defaultColorTone;
  final String? defaultBackgroundImagePath;
  final PageLayoutType defaultLayoutType;

  DefaultStoryPreferencesObject({
    this.defaultColorSeedValue,
    this.defaultColorTone,
    this.defaultBackgroundImagePath,
    PageLayoutType? defaultLayoutType,
  }) : defaultLayoutType = defaultLayoutType ?? PageLayoutType.list;

  Map<String, dynamic> toJson() => _$DefaultStoryPreferencesObjectToJson(this);
  factory DefaultStoryPreferencesObject.fromJson(Map<String, dynamic> json) =>
      _$DefaultStoryPreferencesObjectFromJson(json);

  StoryPreferencesDbModel? toStoryPreference() {
    return StoryPreferencesDbModel(
      showDayCount: null,
      colorSeedValue: defaultColorSeedValue,
      colorTone: defaultColorTone,
      backgroundImagePath: defaultBackgroundImagePath,
      fontFamily: null,
      fontSize: null,
      fontWeightIndex: null,
      titleFontFamily: null,
      titleFontWeightIndex: null,
      titleExpanded: null,
      layoutType: defaultLayoutType,
    );
  }
}
