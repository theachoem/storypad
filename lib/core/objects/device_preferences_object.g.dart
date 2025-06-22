// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_preferences_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DevicePreferencesObjectCWProxy {
  DevicePreferencesObject fontFamily(String? fontFamily);

  DevicePreferencesObject fontWeightIndex(int? fontWeightIndex);

  DevicePreferencesObject themeMode(ThemeMode? themeMode);

  DevicePreferencesObject timeFormat(TimeFormatOption? timeFormat);

  DevicePreferencesObject colorSeedValue(int? colorSeedValue);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DevicePreferencesObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DevicePreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ````
  DevicePreferencesObject call({
    String? fontFamily,
    int? fontWeightIndex,
    ThemeMode? themeMode,
    TimeFormatOption? timeFormat,
    int? colorSeedValue,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDevicePreferencesObject.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDevicePreferencesObject.copyWith.fieldName(...)`
class _$DevicePreferencesObjectCWProxyImpl
    implements _$DevicePreferencesObjectCWProxy {
  const _$DevicePreferencesObjectCWProxyImpl(this._value);

  final DevicePreferencesObject _value;

  @override
  DevicePreferencesObject fontFamily(String? fontFamily) =>
      this(fontFamily: fontFamily);

  @override
  DevicePreferencesObject fontWeightIndex(int? fontWeightIndex) =>
      this(fontWeightIndex: fontWeightIndex);

  @override
  DevicePreferencesObject themeMode(ThemeMode? themeMode) =>
      this(themeMode: themeMode);

  @override
  DevicePreferencesObject timeFormat(TimeFormatOption? timeFormat) =>
      this(timeFormat: timeFormat);

  @override
  DevicePreferencesObject colorSeedValue(int? colorSeedValue) =>
      this(colorSeedValue: colorSeedValue);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DevicePreferencesObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DevicePreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ````
  DevicePreferencesObject call({
    Object? fontFamily = const $CopyWithPlaceholder(),
    Object? fontWeightIndex = const $CopyWithPlaceholder(),
    Object? themeMode = const $CopyWithPlaceholder(),
    Object? timeFormat = const $CopyWithPlaceholder(),
    Object? colorSeedValue = const $CopyWithPlaceholder(),
  }) {
    return DevicePreferencesObject(
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
      timeFormat: timeFormat == const $CopyWithPlaceholder()
          ? _value.timeFormat
          // ignore: cast_nullable_to_non_nullable
          : timeFormat as TimeFormatOption?,
      colorSeedValue: colorSeedValue == const $CopyWithPlaceholder()
          ? _value.colorSeedValue
          // ignore: cast_nullable_to_non_nullable
          : colorSeedValue as int?,
    );
  }
}

extension $DevicePreferencesObjectCopyWith on DevicePreferencesObject {
  /// Returns a callable class that can be used as follows: `instanceOfDevicePreferencesObject.copyWith(...)` or like so:`instanceOfDevicePreferencesObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DevicePreferencesObjectCWProxy get copyWith =>
      _$DevicePreferencesObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevicePreferencesObject _$DevicePreferencesObjectFromJson(
        Map<String, dynamic> json) =>
    DevicePreferencesObject(
      fontFamily: json['font_family'] as String?,
      fontWeightIndex: (json['font_weight_index'] as num?)?.toInt(),
      themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['theme_mode']),
      timeFormat:
          $enumDecodeNullable(_$TimeFormatOptionEnumMap, json['time_format']),
      colorSeedValue: (json['color_seed_value'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DevicePreferencesObjectToJson(
        DevicePreferencesObject instance) =>
    <String, dynamic>{
      'font_weight_index': instance.fontWeightIndex,
      'color_seed_value': instance.colorSeedValue,
      'font_family': instance.fontFamily,
      'theme_mode': _$ThemeModeEnumMap[instance.themeMode]!,
      'time_format': _$TimeFormatOptionEnumMap[instance.timeFormat]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$TimeFormatOptionEnumMap = {
  TimeFormatOption.h12: 'h12',
  TimeFormatOption.h24: 'h24',
};
