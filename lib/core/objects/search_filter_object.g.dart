// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_filter_object.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchFilterObjectCWProxy {
  SearchFilterObject years(Set<int> years);

  SearchFilterObject types(Set<PathType> types);

  SearchFilterObject tagId(int? tagId);

  SearchFilterObject assetId(int? assetId);

  SearchFilterObject templateId(int? templateId);

  SearchFilterObject excludeYears(Set<int>? excludeYears);

  SearchFilterObject month(int? month);

  SearchFilterObject day(int? day);

  SearchFilterObject starred(bool? starred);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SearchFilterObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SearchFilterObject(...).copyWith(id: 12, name: "My name")
  /// ```
  SearchFilterObject call({
    Set<int> years,
    Set<PathType> types,
    int? tagId,
    int? assetId,
    int? templateId,
    Set<int>? excludeYears,
    int? month,
    int? day,
    bool? starred,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSearchFilterObject.copyWith(...)` or call `instanceOfSearchFilterObject.copyWith.fieldName(value)` for a single field.
class _$SearchFilterObjectCWProxyImpl implements _$SearchFilterObjectCWProxy {
  const _$SearchFilterObjectCWProxyImpl(this._value);

  final SearchFilterObject _value;

  @override
  SearchFilterObject years(Set<int> years) => call(years: years);

  @override
  SearchFilterObject types(Set<PathType> types) => call(types: types);

  @override
  SearchFilterObject tagId(int? tagId) => call(tagId: tagId);

  @override
  SearchFilterObject assetId(int? assetId) => call(assetId: assetId);

  @override
  SearchFilterObject templateId(int? templateId) =>
      call(templateId: templateId);

  @override
  SearchFilterObject excludeYears(Set<int>? excludeYears) =>
      call(excludeYears: excludeYears);

  @override
  SearchFilterObject month(int? month) => call(month: month);

  @override
  SearchFilterObject day(int? day) => call(day: day);

  @override
  SearchFilterObject starred(bool? starred) => call(starred: starred);

  @override

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SearchFilterObject(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SearchFilterObject(...).copyWith(id: 12, name: "My name")
  /// ```
  SearchFilterObject call({
    Object? years = const $CopyWithPlaceholder(),
    Object? types = const $CopyWithPlaceholder(),
    Object? tagId = const $CopyWithPlaceholder(),
    Object? assetId = const $CopyWithPlaceholder(),
    Object? templateId = const $CopyWithPlaceholder(),
    Object? excludeYears = const $CopyWithPlaceholder(),
    Object? month = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
    Object? starred = const $CopyWithPlaceholder(),
  }) {
    return SearchFilterObject(
      years: years == const $CopyWithPlaceholder() || years == null
          ? _value.years
          // ignore: cast_nullable_to_non_nullable
          : years as Set<int>,
      types: types == const $CopyWithPlaceholder() || types == null
          ? _value.types
          // ignore: cast_nullable_to_non_nullable
          : types as Set<PathType>,
      tagId: tagId == const $CopyWithPlaceholder()
          ? _value.tagId
          // ignore: cast_nullable_to_non_nullable
          : tagId as int?,
      assetId: assetId == const $CopyWithPlaceholder()
          ? _value.assetId
          // ignore: cast_nullable_to_non_nullable
          : assetId as int?,
      templateId: templateId == const $CopyWithPlaceholder()
          ? _value.templateId
          // ignore: cast_nullable_to_non_nullable
          : templateId as int?,
      excludeYears: excludeYears == const $CopyWithPlaceholder()
          ? _value.excludeYears
          // ignore: cast_nullable_to_non_nullable
          : excludeYears as Set<int>?,
      month: month == const $CopyWithPlaceholder()
          ? _value.month
          // ignore: cast_nullable_to_non_nullable
          : month as int?,
      day: day == const $CopyWithPlaceholder()
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as int?,
      starred: starred == const $CopyWithPlaceholder()
          ? _value.starred
          // ignore: cast_nullable_to_non_nullable
          : starred as bool?,
    );
  }
}

extension $SearchFilterObjectCopyWith on SearchFilterObject {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSearchFilterObject.copyWith(...)` or `instanceOfSearchFilterObject.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchFilterObjectCWProxy get copyWith =>
      _$SearchFilterObjectCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchFilterObject _$SearchFilterObjectFromJson(Map<String, dynamic> json) =>
    SearchFilterObject(
      years: (json['years'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toSet(),
      types: (json['types'] as List<dynamic>)
          .map((e) => $enumDecode(_$PathTypeEnumMap, e))
          .toSet(),
      tagId: (json['tag_id'] as num?)?.toInt(),
      assetId: (json['asset_id'] as num?)?.toInt(),
      templateId: (json['template_id'] as num?)?.toInt(),
      excludeYears: (json['exclude_years'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toSet(),
      month: (json['month'] as num?)?.toInt(),
      day: (json['day'] as num?)?.toInt(),
      starred: json['starred'] as bool?,
    );

Map<String, dynamic> _$SearchFilterObjectToJson(SearchFilterObject instance) =>
    <String, dynamic>{
      'years': instance.years.toList(),
      'exclude_years': instance.excludeYears?.toList(),
      'month': instance.month,
      'day': instance.day,
      'types': instance.types.map((e) => _$PathTypeEnumMap[e]!).toList(),
      'tag_id': instance.tagId,
      'template_id': instance.templateId,
      'asset_id': instance.assetId,
      'starred': instance.starred,
    };

const _$PathTypeEnumMap = {
  PathType.docs: 'docs',
  PathType.bins: 'bins',
  PathType.archives: 'archives',
};
