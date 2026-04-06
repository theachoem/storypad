// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_story_preferences_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DefaultStoryPreferencesObjectCWProxy {
  DefaultStoryPreferencesObject defaultColorSeedValue(
    int? defaultColorSeedValue,
  );

  DefaultStoryPreferencesObject defaultColorTone(int? defaultColorTone);

  DefaultStoryPreferencesObject defaultBackgroundImagePath(
    String? defaultBackgroundImagePath,
  );

  DefaultStoryPreferencesObject defaultLayoutType(
    PageLayoutType? defaultLayoutType,
  );

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DefaultStoryPreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DefaultStoryPreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  DefaultStoryPreferencesObject call({
    int? defaultColorSeedValue,
    int? defaultColorTone,
    String? defaultBackgroundImagePath,
    PageLayoutType? defaultLayoutType,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDefaultStoryPreferencesObject.copyWith(...)` or call `instanceOfDefaultStoryPreferencesObject.copyWith.fieldName(value)` for a single field.
class _$DefaultStoryPreferencesObjectCWProxyImpl
    implements _$DefaultStoryPreferencesObjectCWProxy {
  const _$DefaultStoryPreferencesObjectCWProxyImpl(this._value);

  final DefaultStoryPreferencesObject _value;

  @override
  DefaultStoryPreferencesObject defaultColorSeedValue(
    int? defaultColorSeedValue,
  ) => call(defaultColorSeedValue: defaultColorSeedValue);

  @override
  DefaultStoryPreferencesObject defaultColorTone(int? defaultColorTone) =>
      call(defaultColorTone: defaultColorTone);

  @override
  DefaultStoryPreferencesObject defaultBackgroundImagePath(
    String? defaultBackgroundImagePath,
  ) => call(defaultBackgroundImagePath: defaultBackgroundImagePath);

  @override
  DefaultStoryPreferencesObject defaultLayoutType(
    PageLayoutType? defaultLayoutType,
  ) => call(defaultLayoutType: defaultLayoutType);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `DefaultStoryPreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DefaultStoryPreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  DefaultStoryPreferencesObject call({
    Object? defaultColorSeedValue = const $CopyWithPlaceholder(),
    Object? defaultColorTone = const $CopyWithPlaceholder(),
    Object? defaultBackgroundImagePath = const $CopyWithPlaceholder(),
    Object? defaultLayoutType = const $CopyWithPlaceholder(),
  }) {
    return DefaultStoryPreferencesObject(
      defaultColorSeedValue:
          defaultColorSeedValue == const $CopyWithPlaceholder()
          ? _value.defaultColorSeedValue
          // ignore: cast_nullable_to_non_nullable
          : defaultColorSeedValue as int?,
      defaultColorTone: defaultColorTone == const $CopyWithPlaceholder()
          ? _value.defaultColorTone
          // ignore: cast_nullable_to_non_nullable
          : defaultColorTone as int?,
      defaultBackgroundImagePath:
          defaultBackgroundImagePath == const $CopyWithPlaceholder()
          ? _value.defaultBackgroundImagePath
          // ignore: cast_nullable_to_non_nullable
          : defaultBackgroundImagePath as String?,
      defaultLayoutType: defaultLayoutType == const $CopyWithPlaceholder()
          ? _value.defaultLayoutType
          // ignore: cast_nullable_to_non_nullable
          : defaultLayoutType as PageLayoutType?,
    );
  }
}

extension $DefaultStoryPreferencesObjectCopyWith
    on DefaultStoryPreferencesObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDefaultStoryPreferencesObject.copyWith(...)` or `instanceOfDefaultStoryPreferencesObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DefaultStoryPreferencesObjectCWProxy get copyWith =>
      _$DefaultStoryPreferencesObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefaultStoryPreferencesObject _$DefaultStoryPreferencesObjectFromJson(
  Map<String, dynamic> json,
) => DefaultStoryPreferencesObject(
  defaultColorSeedValue: (json['default_color_seed_value'] as num?)?.toInt(),
  defaultColorTone: (json['default_color_tone'] as num?)?.toInt(),
  defaultBackgroundImagePath: json['default_background_image_path'] as String?,
  defaultLayoutType: $enumDecodeNullable(
    _$PageLayoutTypeEnumMap,
    json['default_layout_type'],
  ),
);

Map<String, dynamic> _$DefaultStoryPreferencesObjectToJson(
  DefaultStoryPreferencesObject instance,
) => <String, dynamic>{
  'default_color_seed_value': instance.defaultColorSeedValue,
  'default_color_tone': instance.defaultColorTone,
  'default_background_image_path': instance.defaultBackgroundImagePath,
  'default_layout_type': _$PageLayoutTypeEnumMap[instance.defaultLayoutType]!,
};

const _$PageLayoutTypeEnumMap = {
  PageLayoutType.list: 'list',
  PageLayoutType.grid: 'grid',
  PageLayoutType.pages: 'pages',
};
