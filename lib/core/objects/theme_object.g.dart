// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThemeObject _$ThemeObjectFromJson(Map<String, dynamic> json) => ThemeObject(
  fontFamily: json['font_family'] as String?,
  fontWeightIndex: (json['font_weight_index'] as num?)?.toInt(),
  themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['theme_mode']),
  colorSeedValue: (json['color_seed_value'] as num?)?.toInt(),
);

Map<String, dynamic> _$ThemeObjectToJson(ThemeObject instance) =>
    <String, dynamic>{
      'font_weight_index': instance.fontWeightIndex,
      'color_seed_value': instance.colorSeedValue,
      'font_family': instance.fontFamily,
      'theme_mode': _$ThemeModeEnumMap[instance.themeMode]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
