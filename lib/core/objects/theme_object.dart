// TODO: tix deprecation
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:storypad/core/constants/app_constants.dart';

part 'theme_object.g.dart';

@JsonSerializable()
class ThemeObject {
  @JsonKey(name: 'font_family')
  final String? _fontFamily;
  final int? fontWeightIndex;

  @JsonKey(name: 'theme_mode')
  final ThemeMode? _themeMode;
  final int? colorSeedValue;

  String get fontFamily => _fontFamily ?? kDefaultFontFamily;
  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;
  Color? get colorSeed => colorSeedValue != null ? Color(colorSeedValue!) : null;
  FontWeight get fontWeight => fontWeightIndex != null ? FontWeight.values[fontWeightIndex!] : kDefaultFontWeight;

  ThemeObject({
    String? fontFamily,
    this.fontWeightIndex,
    ThemeMode? themeMode,
    this.colorSeedValue,
  })  : _fontFamily = fontFamily,
        _themeMode = themeMode;

  factory ThemeObject.initial() {
    return ThemeObject(
      colorSeedValue: Colors.black.value,
    );
  }

  ThemeObject copyWith({
    String? fontFamily,
    FontWeight? fontWeight,
    ThemeMode? themeMode,
    Color? colorSeed,
  }) {
    return ThemeObject(
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeightIndex: fontWeight?.index ?? fontWeightIndex,
      themeMode: themeMode ?? this.themeMode,
      colorSeedValue: colorSeed?.value ?? colorSeedValue,
    );
  }

  ThemeObject copyWithNewColor(
    Color colorSeed, {
    bool removeIfSame = true,
  }) {
    Color? newColorSeed = colorSeed;
    if (removeIfSame) newColorSeed = colorSeed.value != colorSeedValue ? colorSeed : null;
    return ThemeObject(
      fontFamily: fontFamily,
      fontWeightIndex: fontWeight.index,
      themeMode: themeMode,
      colorSeedValue: newColorSeed?.value,
    );
  }

  Map<String, dynamic> toJson() => _$ThemeObjectToJson(this);
  factory ThemeObject.fromJson(Map<String, dynamic> json) => _$ThemeObjectFromJson(json);
}
