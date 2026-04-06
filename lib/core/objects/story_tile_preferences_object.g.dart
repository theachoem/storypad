// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_tile_preferences_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryTilePreferencesObjectCWProxy {
  StoryTilePreferencesObject showTime(bool? showTime);

  StoryTilePreferencesObject showPageCount(bool? showPageCount);

  StoryTilePreferencesObject showTagLabels(bool? showTagLabels);

  StoryTilePreferencesObject showVoiceCount(bool? showVoiceCount);

  StoryTilePreferencesObject displayCharacterCount(int? displayCharacterCount);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryTilePreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryTilePreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryTilePreferencesObject call({
    bool? showTime,
    bool? showPageCount,
    bool? showTagLabels,
    bool? showVoiceCount,
    int? displayCharacterCount,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStoryTilePreferencesObject.copyWith(...)` or call `instanceOfStoryTilePreferencesObject.copyWith.fieldName(value)` for a single field.
class _$StoryTilePreferencesObjectCWProxyImpl
    implements _$StoryTilePreferencesObjectCWProxy {
  const _$StoryTilePreferencesObjectCWProxyImpl(this._value);

  final StoryTilePreferencesObject _value;

  @override
  StoryTilePreferencesObject showTime(bool? showTime) =>
      call(showTime: showTime);

  @override
  StoryTilePreferencesObject showPageCount(bool? showPageCount) =>
      call(showPageCount: showPageCount);

  @override
  StoryTilePreferencesObject showTagLabels(bool? showTagLabels) =>
      call(showTagLabels: showTagLabels);

  @override
  StoryTilePreferencesObject showVoiceCount(bool? showVoiceCount) =>
      call(showVoiceCount: showVoiceCount);

  @override
  StoryTilePreferencesObject displayCharacterCount(
    int? displayCharacterCount,
  ) => call(displayCharacterCount: displayCharacterCount);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryTilePreferencesObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryTilePreferencesObject(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryTilePreferencesObject call({
    Object? showTime = const $CopyWithPlaceholder(),
    Object? showPageCount = const $CopyWithPlaceholder(),
    Object? showTagLabels = const $CopyWithPlaceholder(),
    Object? showVoiceCount = const $CopyWithPlaceholder(),
    Object? displayCharacterCount = const $CopyWithPlaceholder(),
  }) {
    return StoryTilePreferencesObject(
      showTime: showTime == const $CopyWithPlaceholder()
          ? _value.showTime
          // ignore: cast_nullable_to_non_nullable
          : showTime as bool?,
      showPageCount: showPageCount == const $CopyWithPlaceholder()
          ? _value.showPageCount
          // ignore: cast_nullable_to_non_nullable
          : showPageCount as bool?,
      showTagLabels: showTagLabels == const $CopyWithPlaceholder()
          ? _value.showTagLabels
          // ignore: cast_nullable_to_non_nullable
          : showTagLabels as bool?,
      showVoiceCount: showVoiceCount == const $CopyWithPlaceholder()
          ? _value.showVoiceCount
          // ignore: cast_nullable_to_non_nullable
          : showVoiceCount as bool?,
      displayCharacterCount:
          displayCharacterCount == const $CopyWithPlaceholder()
          ? _value.displayCharacterCount
          // ignore: cast_nullable_to_non_nullable
          : displayCharacterCount as int?,
    );
  }
}

extension $StoryTilePreferencesObjectCopyWith on StoryTilePreferencesObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStoryTilePreferencesObject.copyWith(...)` or `instanceOfStoryTilePreferencesObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryTilePreferencesObjectCWProxy get copyWith =>
      _$StoryTilePreferencesObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryTilePreferencesObject _$StoryTilePreferencesObjectFromJson(
  Map<String, dynamic> json,
) => StoryTilePreferencesObject(
  showTime: json['show_time'] as bool?,
  showPageCount: json['show_page_count'] as bool?,
  showTagLabels: json['show_tag_labels'] as bool?,
  showVoiceCount: json['show_voice_count'] as bool?,
  displayCharacterCount: (json['display_character_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$StoryTilePreferencesObjectToJson(
  StoryTilePreferencesObject instance,
) => <String, dynamic>{
  'show_time': instance.showTime,
  'show_page_count': instance.showPageCount,
  'show_tag_labels': instance.showTagLabels,
  'show_voice_count': instance.showVoiceCount,
  'display_character_count': instance.displayCharacterCount,
};
