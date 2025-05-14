// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_page_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryPageDbModelCWProxy {
  StoryPageDbModel id(int id);

  StoryPageDbModel title(String? title);

  StoryPageDbModel body(List<dynamic>? body);

  StoryPageDbModel crossAxisCount(int? crossAxisCount);

  StoryPageDbModel mainAxisCount(int? mainAxisCount);

  StoryPageDbModel plainText(String? plainText);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPageDbModel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPageDbModel(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPageDbModel call({
    int id,
    String? title,
    List<dynamic>? body,
    int? crossAxisCount,
    int? mainAxisCount,
    String? plainText,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStoryPageDbModel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStoryPageDbModel.copyWith.fieldName(...)`
class _$StoryPageDbModelCWProxyImpl implements _$StoryPageDbModelCWProxy {
  const _$StoryPageDbModelCWProxyImpl(this._value);

  final StoryPageDbModel _value;

  @override
  StoryPageDbModel id(int id) => this(id: id);

  @override
  StoryPageDbModel title(String? title) => this(title: title);

  @override
  StoryPageDbModel body(List<dynamic>? body) => this(body: body);

  @override
  StoryPageDbModel crossAxisCount(int? crossAxisCount) =>
      this(crossAxisCount: crossAxisCount);

  @override
  StoryPageDbModel mainAxisCount(int? mainAxisCount) =>
      this(mainAxisCount: mainAxisCount);

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
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? crossAxisCount = const $CopyWithPlaceholder(),
    Object? mainAxisCount = const $CopyWithPlaceholder(),
    Object? plainText = const $CopyWithPlaceholder(),
  }) {
    return StoryPageDbModel(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as List<dynamic>?,
      crossAxisCount: crossAxisCount == const $CopyWithPlaceholder()
          ? _value.crossAxisCount
          // ignore: cast_nullable_to_non_nullable
          : crossAxisCount as int?,
      mainAxisCount: mainAxisCount == const $CopyWithPlaceholder()
          ? _value.mainAxisCount
          // ignore: cast_nullable_to_non_nullable
          : mainAxisCount as int?,
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
      id: _idFromJson(json['id']),
      title: json['title'] as String?,
      body: json['body'] as List<dynamic>?,
      crossAxisCount: (json['cross_axis_count'] as num?)?.toInt(),
      mainAxisCount: (json['main_axis_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$StoryPageDbModelToJson(StoryPageDbModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'cross_axis_count': instance.crossAxisCount,
      'main_axis_count': instance.mainAxisCount,
    };
