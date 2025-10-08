// TODO: tix deprecation
// ignore_for_file: deprecated_member_use

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/types/font_size_option.dart';
import 'package:storypad/core/types/time_format_option.dart';

part 'device_preferences_object.g.dart';

@CopyWith()
@JsonSerializable()
class DevicePreferencesObject {
  @JsonKey(name: 'font_family')
  final String? _fontFamily;
  final FontSizeOption? fontSize;
  final int? fontWeightIndex;

  @JsonKey(name: 'theme_mode')
  final ThemeMode? _themeMode;
  final int? colorSeedValue;

  @JsonKey(name: 'time_format')
  final TimeFormatOption? _timeFormat;

  String get fontFamily => _fontFamily ?? kDefaultFontFamily;
  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;
  TimeFormatOption get timeFormat => _timeFormat ?? TimeFormatOption.h12;

  Color? get colorSeed => colorSeedValue != null ? Color(colorSeedValue!) : null;
  FontWeight get fontWeight => fontWeightIndex != null ? FontWeight.values[fontWeightIndex!] : kDefaultFontWeight;

  bool get colorSeedCustomized => colorSeed != null;

  DevicePreferencesObject({
    String? fontFamily,
    this.fontSize,
    this.fontWeightIndex,
    ThemeMode? themeMode,
    TimeFormatOption? timeFormat,
    this.colorSeedValue,
  }) : _fontFamily = fontFamily,
       _themeMode = themeMode,
       _timeFormat = timeFormat;

  factory DevicePreferencesObject.initial() {
    return DevicePreferencesObject();
  }

  Map<String, dynamic> toJson() => _$DevicePreferencesObjectToJson(this);
  factory DevicePreferencesObject.fromJson(Map<String, dynamic> json) => _$DevicePreferencesObjectFromJson(json);
}
