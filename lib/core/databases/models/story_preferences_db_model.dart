import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';

part 'story_preferences_db_model.g.dart';

@CopyWith()
@JsonSerializable()
class StoryPreferencesDbModel extends BaseDbModel {
  final String? starIcon;
  final bool? showDayCount;
  final bool? showTime;

  final int? colorSeedValue;
  final String? fontFamily;
  final int? fontWeightIndex;

  final String? titleFontFamily;
  final int? titleFontWeightIndex;

  Color? get colorSeed => colorSeedValue != null ? Color(colorSeedValue!) : null;
  FontWeight? get fontWeight => fontWeightIndex != null ? FontWeight.values[fontWeightIndex!] : null;
  FontWeight? get titleFontWeight => titleFontWeightIndex != null ? FontWeight.values[titleFontWeightIndex!] : null;

  StoryPreferencesDbModel({
    required this.showDayCount,
    required this.starIcon,
    required this.showTime,
    required this.colorSeedValue,
    required this.fontFamily,
    required this.fontWeightIndex,
    required this.titleFontFamily,
    required this.titleFontWeightIndex,
  });

  @override
  int get id => 0;

  @override
  DateTime? get updatedAt => null;

  StoryPreferencesDbModel resetTheme() {
    return copyWith(
      colorSeedValue: null,
      fontFamily: null,
      fontWeightIndex: null,
      titleFontFamily: null,
      titleFontWeightIndex: null,
    );
  }

  factory StoryPreferencesDbModel.create() {
    return StoryPreferencesDbModel(
      showDayCount: false,
      starIcon: null,
      showTime: false,
      colorSeedValue: null,
      fontFamily: null,
      fontWeightIndex: null,
      titleFontFamily: null,
      titleFontWeightIndex: null,
    );
  }

  Map<String, dynamic> toNonNullJson() {
    return toJson()..removeWhere((e, value) => value == null);
  }

  @override
  Map<String, dynamic> toJson() => _$StoryPreferencesDbModelToJson(this);
  factory StoryPreferencesDbModel.fromJson(Map<String, dynamic> json) => _$StoryPreferencesDbModelFromJson(json);
}
