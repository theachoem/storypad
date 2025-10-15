import 'package:storypad/core/types/path_type.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_filter_object.g.dart';

@CopyWith()
@JsonSerializable()
class SearchFilterObject {
  final Set<int> years;
  final Set<int>? excludeYears;
  final int? month;
  final int? day;
  final Set<PathType> types;
  final int? tagId;
  final int? templateId;
  final int? eventId;
  final int? assetId;
  final bool? starred;

  SearchFilterObject({
    required this.years,
    required this.types,
    required this.tagId,
    required this.assetId,
    this.templateId,
    this.eventId,
    this.excludeYears,
    this.month,
    this.day,
    this.starred,
  });

  Map<String, dynamic>? toDatabaseFilter({
    String? query,
  }) {
    Map<String, dynamic> filters = {};

    if (query != null) filters['query'] = query;
    if (years.isNotEmpty) filters['years'] = years.toList();
    if (month != null) filters['month'] = month;
    if (day != null) filters['day'] = day;
    if (tagId != null) filters['tag'] = tagId;
    if (excludeYears != null) filters['exclude_years'] = excludeYears?.toList();
    if (templateId != null) filters['template'] = templateId;
    if (eventId != null) filters['event_id'] = eventId;
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
