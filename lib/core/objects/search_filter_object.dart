import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/types/path_type.dart';

class SearchFilterObject {
  Set<int> years;
  Set<PathType> types;
  int? tagId;
  int? assetId;
  bool? starred;

  final bool filterTagModifiable;

  SearchFilterObject({
    required this.years,
    required this.types,
    required this.tagId,
    required this.assetId,
    this.starred,
    this.filterTagModifiable = true,
  });

  Map<String, dynamic>? toDatabaseFilter({
    String? query,
  }) {
    Map<String, dynamic> filters = {};

    if (query != null) filters['query'] = query;
    if (years.isNotEmpty) filters['years'] = years.toList();
    if (tagId != null) filters['tag'] = tagId;
    if (assetId != null) filters['asset'] = assetId;
    if (starred != null) filters['starred'] = starred;
    if (types.isNotEmpty) filters['types'] = types.map((e) => e.name).toList();

    return filters;
  }

  void toggleYear(int year) {
    if (years.contains(year)) {
      years.remove(year);
    } else {
      years.add(year);
    }
  }

  void toggleType(PathType type) {
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
  }

  void setStarred(bool? value) {
    starred = value;
  }

  void toggleTag(TagDbModel tag) {
    tagId = tag.id == tagId ? null : tag.id;
  }

  factory SearchFilterObject.initial() {
    return SearchFilterObject(
      years: {},
      types: {},
      tagId: null,
      assetId: null,
    );
  }
}
