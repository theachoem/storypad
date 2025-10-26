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

  StoryPageDbModel memoryPlainText(String? memoryPlainText);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryPageDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryPageDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryPageDbModel call({
    int id,
    String? title,
    List<dynamic>? body,
    int? crossAxisCount,
    int? mainAxisCount,
    String? memoryPlainText,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStoryPageDbModel.copyWith(...)` or call `instanceOfStoryPageDbModel.copyWith.fieldName(value)` for a single field.
class _$StoryPageDbModelCWProxyImpl implements _$StoryPageDbModelCWProxy {
  const _$StoryPageDbModelCWProxyImpl(this._value);

  final StoryPageDbModel _value;

  @override
  StoryPageDbModel id(int id) => call(id: id);

  @override
  StoryPageDbModel title(String? title) => call(title: title);

  @override
  StoryPageDbModel body(List<dynamic>? body) => call(body: body);

  @override
  StoryPageDbModel crossAxisCount(int? crossAxisCount) =>
      call(crossAxisCount: crossAxisCount);

  @override
  StoryPageDbModel mainAxisCount(int? mainAxisCount) =>
      call(mainAxisCount: mainAxisCount);

  @override
  StoryPageDbModel memoryPlainText(String? memoryPlainText) =>
      call(memoryPlainText: memoryPlainText);

  @override
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryPageDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryPageDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryPageDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? crossAxisCount = const $CopyWithPlaceholder(),
    Object? mainAxisCount = const $CopyWithPlaceholder(),
    Object? memoryPlainText = const $CopyWithPlaceholder(),
  }) {
    return StoryPageDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
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
      memoryPlainText: memoryPlainText == const $CopyWithPlaceholder()
          ? _value.memoryPlainText
          // ignore: cast_nullable_to_non_nullable
          : memoryPlainText as String?,
    );
  }
}

extension $StoryPageDbModelCopyWith on StoryPageDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStoryPageDbModel.copyWith(...)` or `instanceOfStoryPageDbModel.copyWith.fieldName(...)`.
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
