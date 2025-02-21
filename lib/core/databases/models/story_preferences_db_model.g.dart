// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_preferences_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryPreferencesDbModelCWProxy {
  StoryPreferencesDbModel showDayCount(bool? showDayCount);

  StoryPreferencesDbModel starIcon(String? starIcon);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPreferencesDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPreferencesDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPreferencesDbModel call({
    bool? showDayCount,
    String? starIcon,
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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPreferencesDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPreferencesDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPreferencesDbModel call({
    Object? showDayCount = const $CopyWithPlaceholder(),
    Object? starIcon = const $CopyWithPlaceholder(),
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
    );

Map<String, dynamic> _$StoryPreferencesDbModelToJson(
        StoryPreferencesDbModel instance) =>
    <String, dynamic>{
      'star_icon': instance.starIcon,
      'show_day_count': instance.showDayCount,
    };
