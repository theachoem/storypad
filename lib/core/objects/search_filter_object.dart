import 'package:storypad/core/types/path_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_filter_object.g.dart';

@CopyWith()
@JsonSerializable()
class SearchFilterObject {
  final Set<int> years;
  final int? month;
  final int? day;
  final Set<PathType> types;
  final int? tagId;
  final int? templateId;
  final int? assetId;
  final bool? starred;

  SearchFilterObject({
    required this.years,
    required this.types,
    required this.tagId,
    required this.assetId,
    this.templateId,
    this.month,
    this.day,
    this.starred,
  });

  Map<String, dynamic>? toDatabaseFilter({
    String? query,
  }) {
    Map<String, dynamic> filters = {};

    if (query != null) filters['query'] = query;
    if (years.isNotEmpty) {
      filters['years'] = years.toList();

      // current month & day usecase only with year.
      if (month != null) filters['month'] = month;
      if (day != null) filters['day'] = day;
    }

    if (tagId != null) filters['tag'] = tagId;
    if (templateId != null) filters['template'] = templateId;
    if (assetId != null) filters['asset'] = assetId;
    if (starred != null) filters['starred'] = starred;
    if (types.isNotEmpty) filters['types'] = types.map((e) => e.name).toList();

    // Search whole database when has query.
    if (query != null && query.trim().isNotEmpty == true) {
      filters['types'] = PathType.values.map((e) => e.name).toList();
      filters.remove('years');
    }

    return filters;
  }

  Map<String, dynamic> toJson() => _$SearchFilterObjectToJson(this);
  factory SearchFilterObject.fromJson(Map<String, dynamic> json) => _$SearchFilterObjectFromJson(json);
}
