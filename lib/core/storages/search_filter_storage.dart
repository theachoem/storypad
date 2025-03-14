import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/storages/base_object_storages/object_storage.dart';

class SearchFilterStorage extends ObjectStorage<SearchFilterObject> {
  @override
  SearchFilterObject decode(Map<String, dynamic> json) => SearchFilterObject.fromJson(json);

  @override
  Map<String, dynamic> encode(SearchFilterObject object) => object.toJson();
}
