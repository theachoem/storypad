import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/collection_db_model.dart';
import 'package:storypad/core/databases/models/story_db_model.dart';
import 'package:storypad/core/databases/models/tag_db_model.dart';
import 'package:storypad/core/storages/search_filter_storage.dart';
import 'package:storypad/core/types/path_type.dart';
import 'package:storypad/views/search/filter/search_filter_view.dart';
import 'package:storypad/widgets/story_list/sp_story_list_multi_edit_wrapper.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/services/analytics/analytics_service.dart';
import 'search_view.dart';

class SearchViewModel extends ChangeNotifier with DisposeAwareMixin, DebounchedCallback {
  final SearchRoute params;
  final TextEditingController queryController = TextEditingController();
  final FocusNode queryFocusNode = FocusNode();

  SearchViewModel({
    required this.params,
  }) {
    load();
  }

  SearchFilterObject? searchFilter;
  late final SearchFilterObject initialFilter = SearchFilterObject(
    years: {},
    types: {PathType.docs},
    tagId: null,
    assetId: null,
    limit: 100,
  );

  List<TagDbModel>? _tags;
  List<TagDbModel>? get tags => _tags;

  CollectionDbModel<StoryDbModel>? _stories;
  CollectionDbModel<StoryDbModel> get stories => _stories ?? CollectionDbModel(items: []);

  bool get hasQuery => searchFilter?.query != null;

  Future<void> load() async {
    // StoryPad already persist the all search filters, but when reopening Search
    // only restore the tagId. Other fields (years, types, starred, etc.) are
    // hidden in the UI and restoring them can be confusing.
    // Tags are visibly selectable, so restoring just tagId keeps the UX clear.
    searchFilter = await SearchFilterStorage().readObject().then((value) {
      return initialFilter.copyWith(tagId: value?.tagId);
    });

    _tags = await TagDbModel.db.where().then((e) => e?.items ?? []);
    if (_tags?.isNotEmpty == true) _tags?.insert(0, TagDbModel.fromIDTitle(0, tr('general.all')));

    await _resetTagsCount();
    notifyListeners();
  }

  void searchText(String query) {
    if (searchFilter == null) return;

    debouncedCallback(() async {
      searchFilter = searchFilter!.copyWith(
        query: query.trim().isNotEmpty ? query.trim() : null,
      );
      await _resetTagsCount();
      notifyListeners();

      // query does not need to be remembered.
      SearchFilterStorage().writeObject(searchFilter!.copyWith(query: null));
      AnalyticsService.instance.logSearch(
        searchTerm: query.trim(),
      );
    });
  }

  void clearQuery(BuildContext context) async {
    if (searchFilter == null) return;

    searchFilter = searchFilter!.copyWith(query: null);
    queryController.clear();
    await _resetTagsCount();
    notifyListeners();

    SearchFilterStorage().writeObject(searchFilter!);
  }

  bool tagSelected(TagDbModel tag) => (searchFilter?.tagId == tag.id) || (tag.id == 0 && searchFilter?.tagId == null);

  void toggleTag(TagDbModel tag, BuildContext context) async {
    if (searchFilter == null) return;

    searchFilter = searchFilter!.copyWith(
      tagId: tag.id == searchFilter!.tagId || tag.id == 0 ? null : tag.id,
    );

    notifyListeners();

    SearchFilterStorage().writeObject(searchFilter!);

    // Dismiss keyboard to improve UX when selecting tags.
    if (queryFocusNode.hasFocus) queryFocusNode.unfocus();
  }

  Future<void> _resetTagsCount() async {
    if (searchFilter == null) return;

    Map<int, int> storiesCountByTagId = StoryDbModel.db.getStoryCountByTags(
      query: searchFilter!.query,
      tagIds: tags?.map((e) => e.id).toList() ?? [],
      years: searchFilter!.years.toList(),
      types: searchFilter!.types.isNotEmpty ? searchFilter!.types.map((e) => e.name).toList() : null,
    );

    for (TagDbModel tag in tags ?? []) {
      tag.storiesCount = storiesCountByTagId[tag.id] ?? 0;
    }
  }

  Future<void> goToFilterPage(BuildContext context) async {
    if (searchFilter == null) return;

    final result = await SearchFilterRoute(
      initialTune: searchFilter!,
      multiSelectYear: true,
      filterTagModifiable: true,
      resetTune: initialFilter,
    ).push(context);

    if (result is SearchFilterObject) {
      searchFilter = result;
      await _resetTagsCount();
      notifyListeners();
    }
  }

  Future<void> onPopInvokedWithResult(bool didPop, dynamic result, BuildContext context) async {
    if (didPop) return;

    bool shouldPop = true;

    if (SpStoryListMultiEditWrapper.of(context).selectedStories.isNotEmpty) {
      OkCancelResult result = await showOkCancelAlertDialog(
        context: context,
        title: tr("dialog.are_you_sure_to_discard_these_changes.title"),
        isDestructiveAction: true,
        okLabel: tr("button.discard"),
      );
      shouldPop = result == OkCancelResult.ok;
    }

    if (shouldPop && context.mounted) Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    queryController.dispose();
    queryFocusNode.dispose();
    super.dispose();
  }
}
