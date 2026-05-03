import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/core/objects/story_tile_preferences_object.dart';
import 'package:storypad/core/types/first_day_of_week_option.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';

part 'device_preferences_object.g.dart';

@CopyWith()
@JsonSerializable()
class DevicePreferencesObject {
  final String fontFamily;
  final FontSizeOption? fontSize;
  final int? fontWeightIndex;

  final ThemeMode themeMode;
  final int? colorSeedValue;
  final double voicePlaybackSpeed;
  final TimeFormatOption timeFormat;
  final FirstDayOfWeekOption firstDayOfWeek;

  final StoryTilePreferencesObject storyTilePreferences;
  final DefaultStoryPreferencesObject defaultStoryPreferences;

  // Add ons
  final bool? enableRelaxSounds;
  final bool? enablePeriodCalendar;

  Color? get colorSeed => colorSeedValue != null ? Color(colorSeedValue!) : null;
  FontWeight get fontWeight => fontWeightIndex != null ? FontWeight.values[fontWeightIndex!] : kDefaultFontWeight;

  bool get colorSeedCustomized => colorSeed != null;

  DevicePreferencesObject({
    String? fontFamily,
    this.fontSize,
    this.fontWeightIndex,
    this.enableRelaxSounds,
    this.enablePeriodCalendar,
    ThemeMode? themeMode,
    TimeFormatOption? timeFormat,
    FirstDayOfWeekOption? firstDayOfWeek,
    this.colorSeedValue,
    double? voicePlaybackSpeed,
    StoryTilePreferencesObject? storyTilePreferences,
    DefaultStoryPreferencesObject? defaultStoryPreferences,
  }) : fontFamily = fontFamily ?? kDefaultFontFamily,
       themeMode = themeMode ?? ThemeMode.system,
       timeFormat = timeFormat ?? TimeFormatOption.h12,
       firstDayOfWeek = firstDayOfWeek ?? FirstDayOfWeekOption.defaultValue,
       voicePlaybackSpeed = voicePlaybackSpeed ?? 1.0,
       storyTilePreferences = storyTilePreferences ?? StoryTilePreferencesObject(),
       defaultStoryPreferences = defaultStoryPreferences ?? DefaultStoryPreferencesObject();

  factory DevicePreferencesObject.initial() {
    return DevicePreferencesObject();
  }

  Map<String, dynamic> toJson() => _$DevicePreferencesObjectToJson(this);
  factory DevicePreferencesObject.fromJson(Map<String, dynamic> json) => _$DevicePreferencesObjectFromJson(json);
}
