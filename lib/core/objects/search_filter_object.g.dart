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

  SearchFilterObject month(int? month);

  SearchFilterObject day(int? day);

  SearchFilterObject starred(bool? starred);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchFilterObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchFilterObject(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchFilterObject call({
    Set<int> years,
    Set<PathType> types,
    int? tagId,
    int? assetId,
    int? month,
    int? day,
    bool? starred,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearchFilterObject.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearchFilterObject.copyWith.fieldName(...)`
class _$SearchFilterObjectCWProxyImpl implements _$SearchFilterObjectCWProxy {
  const _$SearchFilterObjectCWProxyImpl(this._value);

  final SearchFilterObject _value;

  @override
  SearchFilterObject years(Set<int> years) => this(years: years);

  @override
  SearchFilterObject types(Set<PathType> types) => this(types: types);

  @override
  SearchFilterObject tagId(int? tagId) => this(tagId: tagId);

  @override
  SearchFilterObject assetId(int? assetId) => this(assetId: assetId);

  @override
  SearchFilterObject month(int? month) => this(month: month);

  @override
  SearchFilterObject day(int? day) => this(day: day);

  @override
  SearchFilterObject starred(bool? starred) => this(starred: starred);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchFilterObject(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchFilterObject(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchFilterObject call({
    Object? years = const $CopyWithPlaceholder(),
    Object? types = const $CopyWithPlaceholder(),
    Object? tagId = const $CopyWithPlaceholder(),
    Object? assetId = const $CopyWithPlaceholder(),
    Object? month = const $CopyWithPlaceholder(),
    Object? day = const $CopyWithPlaceholder(),
    Object? starred = const $CopyWithPlaceholder(),
  }) {
    return SearchFilterObject(
      years: years == const $CopyWithPlaceholder()
          ? _value.years
          // ignore: cast_nullable_to_non_nullable
          : years as Set<int>,
      types: types == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfSearchFilterObject.copyWith(...)` or like so:`instanceOfSearchFilterObject.copyWith.fieldName(...)`.
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
      month: (json['month'] as num?)?.toInt(),
      day: (json['day'] as num?)?.toInt(),
      starred: json['starred'] as bool?,
    );

Map<String, dynamic> _$SearchFilterObjectToJson(SearchFilterObject instance) =>
    <String, dynamic>{
      'years': instance.years.toList(),
      'month': instance.month,
      'day': instance.day,
      'types': instance.types.map((e) => _$PathTypeEnumMap[e]!).toList(),
      'tag_id': instance.tagId,
      'asset_id': instance.assetId,
      'starred': instance.starred,
    };

const _$PathTypeEnumMap = {
  PathType.docs: 'docs',
  PathType.bins: 'bins',
  PathType.archives: 'archives',
};
