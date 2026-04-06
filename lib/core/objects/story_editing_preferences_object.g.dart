// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_editing_preferences_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryEditingPreferencesObjectCWProxy {
  StoryEditingPreferencesObject defaultColorSeedValue(
    int? defaultColorSeedValue,
  );

  StoryEditingPreferencesObject defaultColorTone(int? defaultColorTone);

  StoryEditingPreferencesObject defaultBackgroundImagePath(
    String? defaultBackgroundImagePath,
  );

  StoryEditingPreferencesObject enableTitle(bool? enableTitle);

  StoryEditingPreferencesObject defaultLayoutType(
    PageLayoutType? defaultLayoutType,
  );

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryEditingPreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryEditingPreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryEditingPreferencesObject call({
    int? defaultColorSeedValue,
    int? defaultColorTone,
    String? defaultBackgroundImagePath,
    bool? enableTitle,
    PageLayoutType? defaultLayoutType,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStoryEditingPreferencesObject.copyWith(...)` or call `instanceOfStoryEditingPreferencesObject.copyWith.fieldName(value)` for a single field.
class _$StoryEditingPreferencesObjectCWProxyImpl
    implements _$StoryEditingPreferencesObjectCWProxy {
  const _$StoryEditingPreferencesObjectCWProxyImpl(this._value);

  final StoryEditingPreferencesObject _value;

  @override
  StoryEditingPreferencesObject defaultColorSeedValue(
    int? defaultColorSeedValue,
  ) => call(defaultColorSeedValue: defaultColorSeedValue);

  @override
  StoryEditingPreferencesObject defaultColorTone(int? defaultColorTone) =>
      call(defaultColorTone: defaultColorTone);

  @override
  StoryEditingPreferencesObject defaultBackgroundImagePath(
    String? defaultBackgroundImagePath,
  ) => call(defaultBackgroundImagePath: defaultBackgroundImagePath);

  @override
  StoryEditingPreferencesObject enableTitle(bool? enableTitle) =>
      call(enableTitle: enableTitle);

  @override
  StoryEditingPreferencesObject defaultLayoutType(
    PageLayoutType? defaultLayoutType,
  ) => call(defaultLayoutType: defaultLayoutType);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryEditingPreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryEditingPreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryEditingPreferencesObject call({
    Object? defaultColorSeedValue = const $CopyWithPlaceholder(),
    Object? defaultColorTone = const $CopyWithPlaceholder(),
    Object? defaultBackgroundImagePath = const $CopyWithPlaceholder(),
    Object? enableTitle = const $CopyWithPlaceholder(),
    Object? defaultLayoutType = const $CopyWithPlaceholder(),
  }) {
    return StoryEditingPreferencesObject(
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
      enableTitle: enableTitle == const $CopyWithPlaceholder()
          ? _value.enableTitle
          // ignore: cast_nullable_to_non_nullable
          : enableTitle as bool?,
      defaultLayoutType: defaultLayoutType == const $CopyWithPlaceholder()
          ? _value.defaultLayoutType
          // ignore: cast_nullable_to_non_nullable
          : defaultLayoutType as PageLayoutType?,
    );
  }
}

extension $StoryEditingPreferencesObjectCopyWith
    on StoryEditingPreferencesObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStoryEditingPreferencesObject.copyWith(...)` or `instanceOfStoryEditingPreferencesObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryEditingPreferencesObjectCWProxy get copyWith =>
      _$StoryEditingPreferencesObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryEditingPreferencesObject _$StoryEditingPreferencesObjectFromJson(
  Map<String, dynamic> json,
) => StoryEditingPreferencesObject(
  defaultColorSeedValue: (json['default_color_seed_value'] as num?)?.toInt(),
  defaultColorTone: (json['default_color_tone'] as num?)?.toInt(),
  defaultBackgroundImagePath: json['default_background_image_path'] as String?,
  enableTitle: json['enable_title'] as bool?,
  defaultLayoutType: $enumDecodeNullable(
    _$PageLayoutTypeEnumMap,
    json['default_layout_type'],
  ),
);

Map<String, dynamic> _$StoryEditingPreferencesObjectToJson(
  StoryEditingPreferencesObject instance,
) => <String, dynamic>{
  'enable_title': instance.enableTitle,
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
