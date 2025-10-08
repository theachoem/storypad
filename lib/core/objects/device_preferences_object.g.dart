// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_preferences_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DevicePreferencesObjectCWProxy {
  DevicePreferencesObject fontFamily(String? fontFamily);

  DevicePreferencesObject fontSize(FontSizeOption? fontSize);

  DevicePreferencesObject fontWeightIndex(int? fontWeightIndex);

  DevicePreferencesObject themeMode(ThemeMode? themeMode);

  DevicePreferencesObject timeFormat(TimeFormatOption? timeFormat);

  DevicePreferencesObject colorSeedValue(int? colorSeedValue);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DevicePreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  DevicePreferencesObject call({
    String? fontFamily,
    FontSizeOption? fontSize,
    int? fontWeightIndex,
    ThemeMode? themeMode,
    TimeFormatOption? timeFormat,
    int? colorSeedValue,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDevicePreferencesObject.copyWith(...)` or call `instanceOfDevicePreferencesObject.copyWith.fieldName(value)` for a single field.
class _$DevicePreferencesObjectCWProxyImpl
    implements _$DevicePreferencesObjectCWProxy {
  const _$DevicePreferencesObjectCWProxyImpl(this._value);

  final DevicePreferencesObject _value;

  @override
  DevicePreferencesObject fontFamily(String? fontFamily) =>
      call(fontFamily: fontFamily);

  @override
  DevicePreferencesObject fontSize(FontSizeOption? fontSize) =>
      call(fontSize: fontSize);

  @override
  DevicePreferencesObject fontWeightIndex(int? fontWeightIndex) =>
      call(fontWeightIndex: fontWeightIndex);

  @override
  DevicePreferencesObject themeMode(ThemeMode? themeMode) =>
      call(themeMode: themeMode);

  @override
  DevicePreferencesObject timeFormat(TimeFormatOption? timeFormat) =>
      call(timeFormat: timeFormat);

  @override
  DevicePreferencesObject colorSeedValue(int? colorSeedValue) =>
      call(colorSeedValue: colorSeedValue);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DevicePreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  DevicePreferencesObject call({
    Object? fontFamily = const $CopyWithPlaceholder(),
    Object? fontSize = const $CopyWithPlaceholder(),
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
      fontSize: fontSize == const $CopyWithPlaceholder()
          ? _value.fontSize
          // ignore: cast_nullable_to_non_nullable
          : fontSize as FontSizeOption?,
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDevicePreferencesObject.copyWith(...)` or `instanceOfDevicePreferencesObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DevicePreferencesObjectCWProxy get copyWith =>
      _$DevicePreferencesObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevicePreferencesObject _$DevicePreferencesObjectFromJson(
  Map<String, dynamic> json,
) => DevicePreferencesObject(
  fontFamily: json['font_family'] as String?,
  fontSize: $enumDecodeNullable(_$FontSizeOptionEnumMap, json['font_size']),
  fontWeightIndex: (json['font_weight_index'] as num?)?.toInt(),
  themeMode: $enumDecodeNullable(_$ThemeModeEnumMap, json['theme_mode']),
  timeFormat: $enumDecodeNullable(
    _$TimeFormatOptionEnumMap,
    json['time_format'],
  ),
  colorSeedValue: (json['color_seed_value'] as num?)?.toInt(),
);

Map<String, dynamic> _$DevicePreferencesObjectToJson(
  DevicePreferencesObject instance,
) => <String, dynamic>{
  'font_size': _$FontSizeOptionEnumMap[instance.fontSize],
  'font_weight_index': instance.fontWeightIndex,
  'color_seed_value': instance.colorSeedValue,
  'font_family': instance.fontFamily,
  'theme_mode': _$ThemeModeEnumMap[instance.themeMode]!,
  'time_format': _$TimeFormatOptionEnumMap[instance.timeFormat]!,
};

const _$FontSizeOptionEnumMap = {
  FontSizeOption.small: 'small',
  FontSizeOption.normal: 'normal',
  FontSizeOption.large: 'large',
  FontSizeOption.extraLarge: 'extraLarge',
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
