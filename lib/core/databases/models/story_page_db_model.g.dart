// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_page_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryPageDbModelCWProxy {
  StoryPageDbModel title(String? title);

  StoryPageDbModel feeling(String? feeling);

  StoryPageDbModel body(List<dynamic>? body);

  StoryPageDbModel plainText(String? plainText);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPageDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPageDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPageDbModel call({
    String? title,
    String? feeling,
    List<dynamic>? body,
    String? plainText,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStoryPageDbModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStoryPageDbModel.copyWith.fieldName(...)`
class _$StoryPageDbModelCWProxyImpl implements _$StoryPageDbModelCWProxy {
  const _$StoryPageDbModelCWProxyImpl(this._value);

  final StoryPageDbModel _value;

  @override
  StoryPageDbModel title(String? title) => this(title: title);

  @override
  StoryPageDbModel feeling(String? feeling) => this(feeling: feeling);

  @override
  StoryPageDbModel body(List<dynamic>? body) => this(body: body);

  @override
  StoryPageDbModel plainText(String? plainText) => this(plainText: plainText);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPageDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPageDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPageDbModel call({
    Object? title = const $CopyWithPlaceholder(),
    Object? feeling = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? plainText = const $CopyWithPlaceholder(),
  }) {
    return StoryPageDbModel(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      feeling: feeling == const $CopyWithPlaceholder()
          ? _value.feeling
          // ignore: cast_nullable_to_non_nullable
          : feeling as String?,
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as List<dynamic>?,
      plainText: plainText == const $CopyWithPlaceholder()
          ? _value.plainText
          // ignore: cast_nullable_to_non_nullable
          : plainText as String?,
    );
  }
}

extension $StoryPageDbModelCopyWith on StoryPageDbModel {
  /// Returns a callable class that can be used as follows: `instanceOfStoryPageDbModel.copyWith(...)` or like so:`instanceOfStoryPageDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryPageDbModelCWProxy get copyWith => _$StoryPageDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryPageDbModel _$StoryPageDbModelFromJson(Map<String, dynamic> json) =>
    StoryPageDbModel(
      title: json['title'] as String?,
      feeling: json['feeling'] as String?,
      body: json['body'] as List<dynamic>?,
    );

Map<String, dynamic> _$StoryPageDbModelToJson(StoryPageDbModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'feeling': instance.feeling,
      'body': instance.body,
    };
