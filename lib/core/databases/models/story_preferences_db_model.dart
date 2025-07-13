import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:storypad/core/databases/models/base_db_model.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/page_layout_type.dart';

part 'story_preferences_db_model.g.dart';

PageLayoutType _layoutTypeFromJson(dynamic layoutType) {
  for (var type in PageLayoutType.values) {
    if (type.name == layoutType.toString()) {
      return type;
    }
  }

  // fallback old app version layout.
  return PageLayoutType.pages;
}

@CopyWith()
@JsonSerializable()
class StoryPreferencesDbModel extends BaseDbModel {
  final String? starIcon;
  final bool? showDayCount;
  final bool? showTime;

  final int? colorSeedValue;
  final int? colorTone;
  final String? fontFamily;
  final FontSizeOption? fontSize;
  final int? fontWeightIndex;

  final String? titleFontFamily;
  final int? titleFontWeightIndex;
  final bool? titleExpanded;

  @JsonKey(fromJson: _layoutTypeFromJson)
  final PageLayoutType layoutType;

  Color? get colorSeed => colorSeedValue != null ? Color(colorSeedValue!) : null;
  FontWeight? get fontWeight => fontWeightIndex != null ? FontWeight.values[fontWeightIndex!] : null;
  FontWeight? get titleFontWeight => titleFontWeightIndex != null ? FontWeight.values[titleFontWeightIndex!] : null;

  int get colorToneFallback => colorTone ?? 0;
  double get titleFontSize => titleExpandedFallback ? 18.0 : 16.0;
  bool get titleExpandedFallback => titleExpanded ?? true;

  StoryPreferencesDbModel({
    required this.showDayCount,
    required this.starIcon,
    required this.showTime,
    required this.colorSeedValue,
    required this.colorTone,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeightIndex,
    required this.titleFontFamily,
    required this.titleFontWeightIndex,
    required this.titleExpanded,
    required this.layoutType,
  });

  @override
  int get id => 0;

  @override
  DateTime? get updatedAt => null;

  bool get allReseted =>
      [
        colorSeedValue,
        colorTone,
        fontFamily,
        fontSize,
        fontWeightIndex,
        titleFontFamily,
        titleFontWeightIndex,
        titleExpanded,
      ].every((e) => e == null) &&
      layoutType == PageLayoutType.list;

  bool get titleReseted => [
        titleFontFamily,
        titleFontWeightIndex,
        titleExpanded,
      ].every((e) => e == null);

  StoryPreferencesDbModel resetTheme() {
    return copyWith(
      colorSeedValue: null,
      colorTone: null,
      fontFamily: null,
      fontSize: null,
      fontWeightIndex: null,
      titleFontFamily: null,
      titleFontWeightIndex: null,
      titleExpanded: null,
      layoutType: PageLayoutType.list,
    );
  }

  factory StoryPreferencesDbModel.create() {
    return StoryPreferencesDbModel(
      showDayCount: false,
      starIcon: null,
      showTime: false,
      colorSeedValue: null,
      colorTone: null,
      fontFamily: null,
      fontSize: null,
      fontWeightIndex: null,
      titleFontFamily: null,
      titleFontWeightIndex: null,
      layoutType: PageLayoutType.list,
      titleExpanded: null,
    );
  }

  Map<String, dynamic> toNonNullJson() {
    return toJson()..removeWhere((e, value) => value == null);
  }

  @override
  Map<String, dynamic> toJson() => _$StoryPreferencesDbModelToJson(this);
  factory StoryPreferencesDbModel.fromJson(Map<String, dynamic> json) => _$StoryPreferencesDbModelFromJson(json);
}
