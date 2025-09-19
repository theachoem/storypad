// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_content_db_model.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryContentDbModelCWProxy {
  StoryContentDbModel id(int id);

  StoryContentDbModel title(String? title);

  StoryContentDbModel plainText(String? plainText);

  StoryContentDbModel createdAt(DateTime createdAt);

  StoryContentDbModel pages(List<List<dynamic>>? pages);

  StoryContentDbModel richPages(List<StoryPageDbModel>? richPages);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryContentDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryContentDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryContentDbModel call({
    int id,
    String? title,
    String? plainText,
    DateTime createdAt,
    List<List<dynamic>>? pages,
    List<StoryPageDbModel>? richPages,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStoryContentDbModel.copyWith(...)` or call `instanceOfStoryContentDbModel.copyWith.fieldName(value)` for a single field.
class _$StoryContentDbModelCWProxyImpl implements _$StoryContentDbModelCWProxy {
  const _$StoryContentDbModelCWProxyImpl(this._value);

  final StoryContentDbModel _value;

  @override
  StoryContentDbModel id(int id) => call(id: id);

  @override
  StoryContentDbModel title(String? title) => call(title: title);

  @override
  StoryContentDbModel plainText(String? plainText) =>
      call(plainText: plainText);

  @override
  StoryContentDbModel createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  @override
  StoryContentDbModel pages(List<List<dynamic>>? pages) => call(pages: pages);

  @override
  StoryContentDbModel richPages(List<StoryPageDbModel>? richPages) =>
      call(richPages: richPages);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `StoryContentDbModel(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StoryContentDbModel(...).copyWith(id: 12, name: "My name")
  /// ```
  StoryContentDbModel call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? plainText = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? pages = const $CopyWithPlaceholder(),
    Object? richPages = const $CopyWithPlaceholder(),
  }) {
    return StoryContentDbModel(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as int,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      plainText: plainText == const $CopyWithPlaceholder()
          ? _value.plainText
          // ignore: cast_nullable_to_non_nullable
          : plainText as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      pages: pages == const $CopyWithPlaceholder()
          ? _value.pages
          // ignore: cast_nullable_to_non_nullable
          : pages as List<List<dynamic>>?,
      richPages: richPages == const $CopyWithPlaceholder()
          ? _value.richPages
          // ignore: cast_nullable_to_non_nullable
          : richPages as List<StoryPageDbModel>?,
    );
  }
}

extension $StoryContentDbModelCopyWith on StoryContentDbModel {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStoryContentDbModel.copyWith(...)` or `instanceOfStoryContentDbModel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryContentDbModelCWProxy get copyWith =>
      _$StoryContentDbModelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryContentDbModel _$StoryContentDbModelFromJson(Map<String, dynamic> json) =>
    StoryContentDbModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      plainText: json['plain_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      pages: (json['pages'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList(),
      richPages: _richPagesFromJson(json['rich_pages']),
    );

Map<String, dynamic> _$StoryContentDbModelToJson(
        StoryContentDbModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'plain_text': instance.plainText,
      'created_at': instance.createdAt.toIso8601String(),
      'pages': instance.pages,
      'rich_pages': instance.richPages?.map((e) => e.toJson()).toList(),
    };
