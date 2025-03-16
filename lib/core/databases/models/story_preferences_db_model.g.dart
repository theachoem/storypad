// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_preferences_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryPreferencesDbModelCWProxy {
  StoryPreferencesDbModel showDayCount(bool? showDayCount);

  StoryPreferencesDbModel starIcon(String? starIcon);

  StoryPreferencesDbModel showTime(bool? showTime);

  StoryPreferencesDbModel colorSeedValue(int? colorSeedValue);

  StoryPreferencesDbModel fontFamily(String? fontFamily);

  StoryPreferencesDbModel fontWeightIndex(int? fontWeightIndex);

  StoryPreferencesDbModel themeMode(ThemeMode? themeMode);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPreferencesDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPreferencesDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPreferencesDbModel call({
    bool? showDayCount,
    String? starIcon,
    bool? showTime,
    int? colorSeedValue,
    String? fontFamily,
    int? fontWeightIndex,
    ThemeMode? themeMode,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStoryPreferencesDbModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStoryPreferencesDbModel.copyWith.fieldName(...)`
class _$StoryPreferencesDbModelCWProxyImpl
    implements _$StoryPreferencesDbModelCWProxy {
  const _$StoryPreferencesDbModelCWProxyImpl(this._value);

  final StoryPreferencesDbModel _value;

  @override
  StoryPreferencesDbModel showDayCount(bool? showDayCount) =>
      this(showDayCount: showDayCount);

  @override
  StoryPreferencesDbModel starIcon(String? starIcon) =>
      this(starIcon: starIcon);

  @override
  StoryPreferencesDbModel showTime(bool? showTime) => this(showTime: showTime);

  @override
  StoryPreferencesDbModel colorSeedValue(int? colorSeedValue) =>
      this(colorSeedValue: colorSeedValue);

  @override
  StoryPreferencesDbModel fontFamily(String? fontFamily) =>
      this(fontFamily: fontFamily);

  @override
  StoryPreferencesDbModel fontWeightIndex(int? fontWeightIndex) =>
      this(fontWeightIndex: fontWeightIndex);

  @override
  StoryPreferencesDbModel themeMode(ThemeMode? themeMode) =>
      this(themeMode: themeMode);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPreferencesDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPreferencesDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPreferencesDbModel call({
    Object? showDayCount = const $CopyWithPlaceholder(),
    Object? starIcon = const $CopyWithPlaceholder(),
    Object? showTime = const $CopyWithPlaceholder(),
    Object? colorSeedValue = const $CopyWithPlaceholder(),
    Object? fontFamily = const $CopyWithPlaceholder(),
    Object? fontWeightIndex = const $CopyWithPlaceholder(),
    Object? themeMode = const $CopyWithPlaceholder(),
  }) {
    return StoryPreferencesDbModel(
      showDayCount: showDayCount == const $CopyWithPlaceholder()
          ? _value.showDayCount
          // ignore: cast_nullable_to_non_nullable
          : showDayCount as bool?,
      starIcon: starIcon == const $CopyWithPlaceholder()
          ? _value.starIcon
          // ignore: cast_nullable_to_non_nullable
          : starIcon as String?,
      showTime: showTime == const $CopyWithPlaceholder()
          ? _value.showTime
          // ignore: cast_nullable_to_non_nullable
          : showTime as bool?,
      colorSeedValue: colorSeedValue == const $CopyWithPlaceholder()
          ? _value.colorSeedValue
          // ignore: cast_nullable_to_non_nullable
          : colorSeedValue as int?,
      fontFamily: fontFamily == const $CopyWithPlaceholder()
          ? _value.fontFamily
          // ignore: cast_nullable_to_non_nullable
          : fontFamily as String?,
      fontWeightIndex: fontWeightIndex == const $CopyWithPlaceholder()
          ? _value.fontWeightIndex
          // ignore: cast_nullable_to_non_nullable
          : fontWeightIndex as int?,
      themeMode: themeMode == const $CopyWithPlaceholder()
          ? _value.themeMode
          // ignore: cast_nullable_to_non_nullable
          : themeMode as ThemeMode?,
    );
  }
}

extension $StoryPreferencesDbModelCopyWith on StoryPreferencesDbModel {
  /// Returns a callable class that can be used as follows: `instanceOfStoryPreferencesDbModel.copyWith(...)` or like so:`instanceOfStoryPreferencesDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryPreferencesDbModelCWProxy get copyWith =>
      _$StoryPreferencesDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryPreferencesDbModel _$StoryPreferencesDbModelFromJson(
        Map<String, dynamic> json) =>
    StoryPreferencesDbModel(
      showDayCount: json['show_day_count'] as bool?,
      starIcon: json['star_icon'] as String?,
      showTime: json['show_time'] as bool?,
      colorSeedValue: (json['color_seed_value'] as num?)?.toInt(),
      fontFamily: json['font_family'] as String?,
      fontWeightIndex: (json['font_weight_index'] as num?)?.toInt(),
      themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['theme_mode']),
    );

Map<String, dynamic> _$StoryPreferencesDbModelToJson(
        StoryPreferencesDbModel instance) =>
    <String, dynamic>{
      'star_icon': instance.starIcon,
      'show_day_count': instance.showDayCount,
      'show_time': instance.showTime,
      'color_seed_value': instance.colorSeedValue,
      'font_family': instance.fontFamily,
      'font_weight_index': instance.fontWeightIndex,
      'theme_mode': _$ThemeModeEnumMap[instance.themeMode],
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
